package lathe
{
	import flare.basic.*;
	import flare.core.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.primitives.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;

	/**
	 * @author Ariel Nehmad
	 */
	public class Lathe extends Sprite
	{
		[Embed(source = "shape01.zf3d", mimeType = "application/octet-stream")]
		private var Shape01:Class;
		private var scene:Scene3D;
		
		public function Lathe() 
		{
			scene = new Viewer3D( this, null, 0.3 );
			scene.camera = new Camera3D;
			scene.camera.setPosition( 0, 100, -300 );
			scene.camera.lookAt( 0, 0, 0 );
			scene.autoResize = true;
			scene.addChildFromFile( new Shape01 );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		}
		
		private function completeEvent(e:Event):void 
		{
			var shape:Shape3D = scene.getChildrenByClass( Shape3D )[0] as Shape3D;
			
			shape.addChild( new DebugShape( shape ) );
			
			var mesh:Mesh3D = build( shape, 32, 12 )

			mesh.setMaterial( new Shader3D( "", [new TextureMapFilter, new ColorFilter(0x506070), new SpecularFilter], true ) );
			
			scene.addChild( mesh );
		}
		
		public function build( shape:Shape3D, segments:int = 24, steps:int = 12 ):Mesh3D
		{
			var mesh:Mesh3D = new Mesh3D();
			
			for each ( var spline:Spline3D in shape.splines ) {
				
				var indices:Vector.<uint> = new Vector.<uint>;
				var positions:Vector.<Number> = new Vector.<Number>;
				var uvs:Vector.<Number> = new Vector.<Number>;
				var normals:Vector.<Number> = new Vector.<Number>;
				
				var vertex:Vector.<Number> = new Vector.<Number>;
				var normal:Vector.<Number> = new Vector.<Number>;
				var matrix:Matrix3D = new Matrix3D;
				var i:int, j:int;
				
				// get spline points.
				var length:int = spline.knots.length * steps;
				var point:Vector3D = new Vector3D;
				var tangent:Vector3D = new Vector3D;
				var dir:Vector3D = Vector3D.Z_AXIS;
				
				for ( var n:Number = 0; n < 1; n += 1 / length ) {
					spline.getPoint( n, point ); 
					spline.getTangent( n, tangent );
					shape.localToGlobal( point, point );
					shape.localToGlobalVector( tangent, tangent );
					tangent = dir.crossProduct( tangent );
					vertex.push( point.x, point.y, point.z );
					normal.push( tangent.x, tangent.y, tangent.z );
				}
				
				length = vertex.length / 3;
				
				// project vertex positions and normals.
				var out:Vector.<Number> = new Vector.<Number>;
				matrix.identity();
				for ( i = 0; i < segments + 1; i++ ) {
					matrix.appendRotation( 360 / segments, Vector3D.Y_AXIS );
					matrix.transformVectors( vertex, out );
					positions = positions.concat( out );
					matrix.transformVectors( normal, out );
					normals = normals.concat( out );
				}
				
				// uvs.
				for ( i = 0; i < segments + 1; i++ )
					for ( j = 0; j < length; j++ )
						uvs.push( i / segments, j / (length - 1) );
				
				// build indices.
				for ( i = 0; i < segments; i++ ) {
					for ( j = 0; j < length - 1; j++ ) {
						var id0:uint = ((i + 1) * length) + j;
						var id1:uint = (i * length) + j;
						var id2:uint = ((i + 1) * length) + j + 1;
						var id3:uint = (i * length) + j + 1;
						indices.push( id1, id2, id0 );
						indices.push( id2, id1, id3 );
					}
				}
				
				var surf:Surface3D = new Surface3D( "lathe" );
				surf.vertexVector = positions;
				surf.indexVector = indices;
				surf.addVertexData( Surface3D.POSITION );
				surf.addVertexData( Surface3D.UV0, 2, uvs );
				surf.addVertexData( Surface3D.NORMAL, 3, normals );
				mesh.surfaces.push( surf );
			}
			
			return mesh;
		}
	}
}