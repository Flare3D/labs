package gamepad 
{	
	import com.adobe.air.gaming.*;
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	
	/**
	 * @author Ariel Nehmad
	 */
	public class VirtualPad extends Sprite 
	{
		public static const X_AXIS:uint = 1;
		public static const Y_AXIS:uint = 2;
		public static const HIT:uint = 4;
		
		private var startX:Number;
		private var startY:Number;
		private var lastX:Number;
		private var lastY:Number;
		
		private var _x:Number = 0
		private var _y:Number = 0
		private var _width:Number = 10
		private var _height:Number = 10
		private var _normalizedX:Number = 0;
		private var _normalizedY:Number = 0;
		private var _isDown:Boolean = false;
		private var _hit:Boolean;
		
		private var evID:int;
		private var flags:uint;
		private var airGamepad:AIRGamepad;
		
		public var speedX:Number = 0;
		public var speedY:Number = 0;
		
		public function VirtualPad( width:Number, height:Number, flags:uint = 1 + 2 + 4, airGamepad:AIRGamepad = null ) 
		{
			this.airGamepad = airGamepad;
			this.flags = flags;
			
			_width = width;
			_height = height;
			
			if ( airGamepad )
				this.airGamepad.addEventListener( TouchEvent.TOUCH_BEGIN, thouchDownEvent );
				
			if ( !Multitouch.supportsTouchEvents )
				addEventListener( MouseEvent.MOUSE_DOWN, mouseDownEvent );
			else
				addEventListener( TouchEvent.TOUCH_BEGIN, thouchDownEvent );
			
			draw();
		}
		
		private function draw( e:Event = null ):void
		{
			if ( airGamepad ) return;
			
			graphics.clear();
			graphics.beginFill( 0, 0 );
			graphics.lineStyle( 1, 0xa0a0d6, 0.2 );
			graphics.drawRect( 0, 0, _width, _height );
		}
		
		private function mouseDownEvent(e:MouseEvent):void 
		{
			stage.addEventListener( MouseEvent.MOUSE_MOVE, mouseMoveEvent );
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
			start( e.stageX, e.stageY );
		}
		
		private function mouseMoveEvent(e:MouseEvent):void 
		{
			move( e.stageX, e.stageY );
		}
		
		private function mouseUpEvent(e:MouseEvent):void 
		{
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, mouseMoveEvent );
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
			end();
		}
		
		private function thouchDownEvent(e:TouchEvent):void 
		{
			if ( airGamepad ) {
				if ( e.localX < _x || e.localX > _x + _width ) return;
				if ( e.localY < _y || e.localY > _y + _height ) return;
				airGamepad.addEventListener( TouchEvent.TOUCH_MOVE, touchMoveEvent );
				airGamepad.addEventListener( TouchEvent.TOUCH_END, touchUpEvent );
				start( e.localX, e.localY );
			}
			
			evID = e.touchPointID;
			
			if ( stage ) {
				stage.addEventListener( TouchEvent.TOUCH_MOVE, touchMoveEvent );
				stage.addEventListener( TouchEvent.TOUCH_END, touchUpEvent );
				start( e.stageX, e.stageY );
			}
		}
		
		private function touchMoveEvent(e:TouchEvent):void 
		{
			if ( evID != e.touchPointID ) return;
			
			if ( airGamepad )
				move( e.localX, e.localY );
			else
				move( e.stageX, e.stageY );
		}
		
		private function touchUpEvent(e:TouchEvent):void 
		{
			if ( evID != e.touchPointID ) return;
			if ( stage ) {
				stage.removeEventListener( TouchEvent.TOUCH_MOVE, touchMoveEvent );
				stage.removeEventListener( TouchEvent.TOUCH_END, touchUpEvent );
			}
			if ( airGamepad ) {
				airGamepad.removeEventListener( TouchEvent.TOUCH_MOVE, touchMoveEvent );
				airGamepad.removeEventListener( TouchEvent.TOUCH_END, touchUpEvent );
			}
			end();
		}
		
		private function start( x:Number, y:Number ):void
		{
			if ( flags & HIT )
				dispatchEvent( new Event( "hit" ) );
			startX = x;
			startY = y;
			lastX = x;
			lastY = y;
			speedX = 0;
			speedY = 0;
			move( x, y );
			_isDown = true;
		}
		
		private function move( x:Number, y:Number ):void
		{
			var w2:Number = _width * 0.5;
			var h2:Number = _height * 0.5;
			if ( airGamepad ) {
				if ( flags & X_AXIS ) normalizedX = (x - _x - w2) / w2;
				if ( flags & Y_AXIS ) normalizedY = (y - _y - h2) / h2;
			} else {
				if ( flags & X_AXIS ) normalizedX = (x - this.x - w2) / w2;
				if ( flags & Y_AXIS ) normalizedY = (y - this.y - h2) / h2;
			}
			if ( flags & X_AXIS ) speedX += (x - lastX);
			if ( flags & Y_AXIS ) speedY += (y - lastY);
			lastX = x;
			lastY = y;
		}
		
		private function end():void
		{
			speedX = 0;
			speedY = 0;
			_normalizedX = 0;
			_normalizedY = 0;
			_isDown = false;
		}

		public function get normalizedX():Number 
		{
			return _normalizedX;
		}
		
		public function set normalizedX(value:Number):void 
		{
			_normalizedX = value;
		}
		
		public function get normalizedY():Number 
		{
			return _normalizedY;
		}
		
		public function set normalizedY(value:Number):void 
		{
			_normalizedY = value;
		}
		
		public function get isDown():Boolean 
		{
			return _isDown;
		}
		
		public function set isDown(value:Boolean):void 
		{
			_isDown = value;
		}
		
		public function setSize( x:Number, y:Number, width:Number, height:Number ):void
		{
			this.x = x;
			this.y = y;
			_x = x;
			_y = y;
			_width = width;
			_height = height;
			
			draw();
		}
	}
}

