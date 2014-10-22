package  
{
	import flare.basic.*;
	import flare.core.*;
	import flare.flsl.*;
	import flare.materials.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	public class Morph extends Sprite 
	{
		[Embed(source = "morph.zf3d", mimeType = "application/octet-stream")] private var Morph:Class;
		[Embed(source = "morph.flsl.compiled", mimeType = "application/octet-stream")] private var MorphFilter:Class;
		
		private var morph:FLSLFilter = new FLSLFilter(new MorphFilter);
		private var scene:Scene3D;
		
		public function Morph() 
		{
			scene = new Viewer3D(this, null, 0.2);
			scene.autoResize = true;
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.addChildFromFile(new Morph);
		}
		
		private function completeEvent(e:Event):void 
		{
			scene.camera.setPosition( 50, 100, -150 );
			scene.camera.lookAt( 0, 0, 0 );
			
			var shader:Shader3D = new Shader3D("morph", null, true, morph);
			
			var box1:Surface3D = (scene.getChildByName("Box001") as Mesh3D).surfaces[0];
			var box2:Surface3D = (scene.getChildByName("Box002") as Mesh3D).surfaces[0];
			var box3:Surface3D = (scene.getChildByName("Box003") as Mesh3D).surfaces[0];
			var box4:Surface3D = (scene.getChildByName("Box004") as Mesh3D).surfaces[0];
			
			box2.offset[10] = box2.offset[Surface3D.POSITION]; box2.format[10] = "float3";
			box2.offset[11] = box2.offset[Surface3D.NORMAL]; box2.format[11] = "float3";
			box3.offset[12] = box2.offset[Surface3D.POSITION]; box3.format[12] = "float3";
			box3.offset[13] = box2.offset[Surface3D.NORMAL]; box3.format[13] = "float3";
			box4.offset[14] = box2.offset[Surface3D.POSITION]; box4.format[14] = "float3";
			box4.offset[15] = box2.offset[Surface3D.NORMAL]; box4.format[15] = "float3";
			
			box1.addExternalSource( 10, box2 );
			box1.addExternalSource( 11, box2 );
			box1.addExternalSource( 12, box3 );
			box1.addExternalSource( 13, box3 );
			box1.addExternalSource( 14, box4 );
			box1.addExternalSource( 15, box4 );
			
			box1.material = shader;
			
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):void 
		{
			//morph.params.morph.value[0] = Math.abs( Math.cos( getTimer() / 1000 ) );
			//morph.params.morph.value[1] = Math.abs( Math.cos( getTimer() / 2000 ) );
			morph.params.morph.value[2] = Math.abs( Math.sin( getTimer() / 1500 ) );
		}
		
	}

}