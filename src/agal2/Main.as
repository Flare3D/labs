package agal2
{
	import flare.basic.*;
	import flare.core.*;
	import flare.flsl.*;
	import flare.loaders.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.physics.colliders.*;
	import flare.primitives.*;
	import flare.system.*;
	import flare.utils.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;
	
	[SWF(width = 800, height = 450, frameRate = 60)]
	
	/**
	 * Deferred lighting experiment.
	 * http://www.flare3d.com/demos/agal2
	 * @author Ariel Nehmad
	 */
	public class Main extends Sprite 
	{
		[Embed(source = "assets/fx.flsl.compiled", mimeType = "application/octet-stream")] private var FX:Class;
		[Embed(source = "assets/mrt.flsl.compiled", mimeType = "application/octet-stream")] private var MRT:Class;
		[Embed(source = "assets/lighting.flsl.compiled", mimeType = "application/octet-stream")] private var LIGHTING:Class;
		[Embed(source = "../../assets/white.atf", mimeType = "application/octet-stream")] private var WHITE:Class;
		[Embed(source = "../../assets/map.f3d", mimeType = "application/octet-stream")] private var MAP:Class;
		[Embed(source = "../../assets/sky.atf", mimeType = "application/octet-stream")] private var SKY:Class;
		
		// just some basic setup before creating the shader materials.
		FLSL.agalVersion = 2;
		Device3D.profile = Context3DProfile.STANDARD;
		
		// rendering.
		private var scene:Scene3D;
		private var light:Sphere = new Sphere( "light", 1 );
		private var renderer:FLSLMaterial = new FLSLMaterial( "renderer", new MRT, null, true );
		private var lighting:FLSLMaterial = new FLSLMaterial( "lighting", new LIGHTING, null, true );
		private var fx:FLSLMaterial = new FLSLMaterial( "fx", new FX, null, true );
		private var white:Texture3D = new Texture3D(new WHITE);
		private var skyTexture:Texture3D = new Texture3D(new SKY);
		private var skySphere:Sphere = new Sphere( "sky", 5000 );
		private var vector:Vector3D = new Vector3D;
		private var cameraMatrix:Matrix3D = new Matrix3D;
		
		// dynamic textures.
		private var colorBuffer:Texture3D;
		private var gBuffer:Texture3D;
		private var lightBuffer:Texture3D;
		private var targetBuffer:Texture3D;
		private var glow0:Texture3D;
		private var glow1:Texture3D;
		
		// movement.
		private var player:Pivot3D;
		private var playerTurnX:Number = 0;
		private var playerTurnY:Number = 0;
		private var playerVel:Number = 0;
		private var velY:Number = 0;
		private var oldY:Number = 0;
		private var pad0:VirtualPad = new VirtualPad( 50, 50, VirtualPad.Y_AXIS );;
		private var pad1:VirtualPad = new VirtualPad( 50, 50, VirtualPad.X_AXIS + VirtualPad.Y_AXIS );;
		
		public function Main() 
		{
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			scene = new Scene3D( this );
			scene.autoResize = true;
			scene.skipFrames = true;
			scene.frameRate = 60;
			scene.backgroundColor = 0x0;
			
			stage.color = 0x0;
			stage.addEventListener( Event.RESIZE, configureBuffers );
			
			if ( Multitouch.supportsTouchEvents ) {
				addChild( pad0 );
				addChild( pad1 );
			}
			
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.addChildFromFile( new MAP )
		}
		
		private function completeEvent(e:Event):void 
		{
			configureBuffers();
			
			// this wil be our player.
			player = new Pivot3D( "ourPlayer" );
			player.parent = scene;
			player.setPosition( 0, 100, -100 );
			player.collider = new SphereCollider(20);
			player.collider.collectContacts = true;
			player.collider.neverSleep = true;
			oldY = player.y;
			
			scene.camera.setPosition( 0, 50, 0 );
			scene.camera.fovMode = Camera3D.FOV_VERTICAL;
			scene.camera.fieldOfView = 70;
			scene.camera.parent = player;
			scene.camera.near = 10;
			scene.camera.far = 1200;
			
			// replace current scene material by the new deferred ones.
			var mats:Vector.<Material3D> = scene.getMaterials();
			for each ( var s:Shader3D in mats ) {
				var m:DeferredMaterial = convertMaterial( s );
				scene.replaceMaterial( s, m );
			}
			
			scene.setStatic(true);
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
		}
		
		private function updateEvent(e:Event):void 
		{
			Device3D.temporal0.copyFrom( scene.camera.world );
			
			if ( Input3D.keyDown(Input3D.UP) || Input3D.keyDown(Input3D.W) ) playerVel += 0.15;
			if ( Input3D.keyDown(Input3D.DOWN) || Input3D.keyDown(Input3D.S) ) playerVel -= 0.15;
			
			if ( pad0.isDown ) {
				if ( pad0.normalizedY < 0 ) playerVel += 0.15;
				if ( pad0.normalizedY > 0 ) playerVel -= 0.15;
			}
			if ( Multitouch.supportsTouchEvents ) {
				if ( pad1.isDown ) {
					playerTurnY += pad1.speedX * 0.1;
					playerTurnX += pad1.speedY * 0.1;
					pad1.speedX = 0;
					pad1.speedY = 0;
				}
			} else {
				if ( Input3D.mouseDown ) {
					playerTurnY += Input3D.mouseXSpeed * 0.1;
					playerTurnX += Input3D.mouseYSpeed * 0.1;
				}
			}
			
			scene.camera.y = Math.cos( getTimer() / 100 ) * playerVel * 2 + 45;
			scene.camera.rotateX( playerTurnX );
			
			playerVel *= 0.95;
			playerTurnX *= 0.8;
			playerTurnY *= 0.8;
			player.y += velY - 0.5;
			player.rotateY( playerTurnY );
			player.translateZ( playerVel );
			
			// update collisions.
			scene.physics.step();
			
			velY = ( player.y - oldY );
			oldY = player.y;
			
			// stores the camera motion in view space to later in the motion blur.
			cameraMatrix.copyFrom( Device3D.temporal0 );
			cameraMatrix.append( scene.camera.viewProjection );
		}
		
		private function renderEvent(e:Event):void 
		{
			// we're going to handle all the rendering stuff by ourselves.
			e.preventDefault();
			
			var p:Pivot3D;
			
			// *** G-Buffer - first texture for diffuse and emissive, and second for normals and depth buffer *** //
			
			scene.context.setRenderToTexture( colorBuffer.texture, true, 0, 0, 0 );
			scene.context.setRenderToTexture( gBuffer.texture, true, 0, 0, 1 );
			scene.context.clear( 0, 0, 0, 1 );
			
			// draw here dynamic and static objects.
			renderer.setTechnique( "base" );
			for each ( p in scene.renderList ) p.draw( false );
			scene.staticBatch.draw( false );
			
			// sky also needs to be rendered in MRT mode.
			renderer.setTechnique( "sky" );
			renderer.params.skybox.value = skyTexture;
			skySphere.draw( false, renderer );
			
			scene.context.setRenderToTexture( null, false, 0, 0, 1 );
			
			// *** Light pass *** //
			
			scene.context.setRenderToTexture( lightBuffer.texture, false, 0 );
			scene.context.clear( 0, 0, 0, 0 );
			
			lighting.setTechnique( "point" );
			// the view ray is used to reconstruct each pixel position using only the depth buffer.
			lighting.params.viewRay.value[0] = Device3D.nearFar[2] * scene.camera.zoom / scene.camera.aspectRatio;
			lighting.params.viewRay.value[1] = Device3D.nearFar[2] * scene.camera.zoom; 
			lighting.params.viewRay.value[2] = Device3D.nearFar[2];
			lighting.params.gBuffer.value = gBuffer;
			
			// draw each light. lights should be batched, but this will work for now.
			for each ( var l:Light3D in scene.lights.list ) {
				if ( l.infinite || l.type == Light3D.DIRECTIONAL ) continue;
				light.copyTransformFrom( l, false );
				light.setScale( l.radius, l.radius, l.radius );
				light.getPosition( false, vector );
				Matrix3DUtils.transformVector( Device3D.view, vector, vector ); // <- stores in 'vector' the light position in camera/view space.
				lighting.params.lightProps.value[0] = vector.x;
				lighting.params.lightProps.value[1] = vector.y;
				lighting.params.lightProps.value[2] = vector.z;
				lighting.params.lightProps.value[3] = 50; // <- light power.
				lighting.params.lightColor.value[0] = l.color.x * l.multiplier;
				lighting.params.lightColor.value[1] = l.color.y * l.multiplier;
				lighting.params.lightColor.value[2] = l.color.z * l.multiplier;
				lighting.params.lightColor.value[3] = l.radius * l.radius;
				light.draw( false, lighting );
			}
			
			// downsampling and blurring light buffer.
			scene.context.setRenderToTexture( glow0.texture );
			scene.context.clear();
			renderer.setTechnique( "emissiveColor" );
			renderer.params.colorBuffer.value = colorBuffer;
			renderer.drawQuad();
			blur( glow0, glow1, 4 );
			
			// compose the final buffer.
			scene.context.setRenderToTexture( targetBuffer.texture, false );
			scene.context.clear();
			renderer.setTechnique( "compose" );
			renderer.params.colorBuffer.value = colorBuffer;
			renderer.params.lightBuffer.value = lightBuffer;
			renderer.params.gBuffer.value = gBuffer;
			renderer.params.glowBuffer.value = glow0;
			renderer.drawQuad();
			
			// and finally render to the main buffer applying some post process! \:D/
			scene.context.setRenderToBackBuffer();
			fx.setTechnique( "motionBlur" );
			fx.params.targetBuffer.value = targetBuffer;
			fx.params.prevViewProj.value = cameraMatrix;
			fx.params.blurScale.value[0] = 1;
			fx.params.blurScale.value[1] = 1;
			fx.params.viewRay.value[0] = Device3D.nearFar[2] * scene.camera.zoom / scene.camera.aspectRatio;
			fx.params.viewRay.value[1] = Device3D.nearFar[2] * scene.camera.zoom; 
			fx.params.viewRay.value[2] = Device3D.nearFar[2];
			fx.drawQuad();
		}
		
		private function blur( t0:Texture3D, t1:Texture3D, quality:int = 1, step:Number = 1 ):Texture3D
		{
			// blur horizontally and vertically in two passes.
			fx.setTechnique( "blur" );
			for ( var i:int = 0; i < quality; i++ ) {
				scene.context.setRenderToTexture( t1.texture );
				scene.context.clear();
				fx.params.targetBuffer.value = t0;
				fx.params.step.value[0] = step / t0.width;
				fx.params.step.value[1] = 0;
				fx.drawQuad();
				scene.context.setRenderToTexture( t0.texture );
				scene.context.clear();
				fx.params.targetBuffer.value = t1;
				fx.params.step.value[0] = 0;
				fx.params.step.value[1] = step / t0.height;
				fx.drawQuad();
			}
			return t0;
		}
		
		public function convertMaterial( src:Shader3D ):DeferredMaterial
		{
			var deferred:DeferredMaterial = new DeferredMaterial(src.name, renderer);
			var diffuse:TextureMapFilter = src.getFilterByClass( TextureMapFilter );
			var color:ColorFilter = src.getFilterByClass( ColorFilter );
			var normal:NormalMapFilter = src.getFilterByClass( NormalMapFilter );
			var specular:SpecularMapFilter = src.getFilterByClass( SpecularMapFilter );
			
			if ( normal ) deferred.normal = normal.texture;
			if ( specular ) deferred.specular = specular.texture;
			
			if ( diffuse ) {
				deferred.diffuse = diffuse.texture;
			} else if ( color ) {
				// we're using a white ATF texture here.
				// this is to aviud the shader to be recompiled for compressed and non-compressed textures at runtime,
				// because we're using the same material for all objects.
				// it would be better to have a color property on the material, but for now this does the job.
				deferred.diffuse = white;
				deferred.emissive = 1;
			}
			
			return deferred;
		}
		
		private function configureBuffers( e:Event = null ):void 
		{
			// if already initialized, dispose those buffers.
			if ( colorBuffer ) {
				colorBuffer.dispose();
				gBuffer.dispose();
				lightBuffer.dispose();
				targetBuffer.dispose();
				glow0.dispose();
				glow1.dispose();
			}
			
			var sizeX:int = stage.stageWidth;
			var sizeY:int = stage.stageHeight;
			var rect:Rectangle = new Rectangle( 0, 0, sizeX, sizeY );
			
			// main buffers.
			colorBuffer = new Texture3D( rect, true, Texture3D.FORMAT_RGBA_HALF_FLOAT );
			gBuffer = new Texture3D( rect, true, Texture3D.FORMAT_RGBA_HALF_FLOAT );
			lightBuffer = new Texture3D( rect, true, Texture3D.FORMAT_RGBA );
			targetBuffer = new Texture3D( rect, true, Texture3D.FORMAT_RGBA );
			
			// glow / emissive buffers.
			rect = rect.clone();
			rect.width *= 0.25;
			rect.height *= 0.25;
			glow0 = new Texture3D( rect, true, Texture3D.FORMAT_RGBA_HALF_FLOAT );
			glow1 = new Texture3D( rect, true, Texture3D.FORMAT_RGBA_HALF_FLOAT );
			
			// place the pads for mobile.
			pad0.x = 10;
			pad0.y = 10;
			pad0.setSize( sizeX * 0.25 - 20, sizeY - 20 );
			pad1.x = sizeX * 0.25 + 10;
			pad1.y = 10;
			pad1.setSize( sizeX * 0.75 - 20, sizeY - 20 );
		}
	}
}