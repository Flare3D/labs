package sao
{
	import flare.core.*;
	import flare.flsl.*;
	import flare.materials.*;
	
	/**
	 * Bassig structure to hold material properties.
	 * @author Ariel Nehmad
	 */
	public class DeferredMaterial extends FLSLMaterial
	{
		private var shader:FLSLMaterial;
		
		public var diffuse:Texture3D;
		public var normal:Texture3D;
		public var specular:Texture3D;
		public var emissive:Number = 0;
		
		public function DeferredMaterial( name:String, shader:FLSLMaterial ) 
		{
			super( name );
			
			this.shader = shader;
		}
		
		override public function draw(pivot:Pivot3D, surf:Surface3D, firstIndex:int = 0, count:int = -1):void 
		{
			if ( !diffuse ) return;
			shader.params.diffuseMap.value = diffuse;
			shader.params.emissive.value[0] = emissive;
			shader.draw(pivot, surf, firstIndex, count);
		}
	}
}