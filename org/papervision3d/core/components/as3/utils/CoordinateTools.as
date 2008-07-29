/**
* @private
*/
package org.papervision3d.core.components.as3.utils
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class CoordinateTools
	{
		protected static var lastRandomRange							:Number = -1;
		protected static var randomlyGeneratedNumbers					:Array = [];
		
		public static function localToLocal(containerFrom:DisplayObject, containerTo:DisplayObject, origin:Point=null):Point
		{
			var point:Point = origin ? origin : new Point();
			point = containerFrom.localToGlobal(point);
			point = containerTo.globalToLocal(point);
			return point;
		}
		
		// zero based random range returned
		public static function random(range:Number):Number
		{
			return Math.floor(Math.random()*range);
		} 
		
		public static function drawLocationDot(x:Number, y:Number, target:Sprite, size:Number=3, color:Number=0xff0000, alpha:Number=1, clear:Boolean=true):void
		{
			if( !target ) return;
			var g:Graphics = target.graphics;
			g.beginFill(color, alpha);
			g.drawCircle(x,y,size);
			g.endFill();
		}
		
		public static function drawBoundingBox(x:Number, y:Number, width:Number, height:Number, target:Sprite, color:Number=0xff0000, alpha:Number=1, clear:Boolean=true):void
		{
			if( !target ) return;
			var g:Graphics = target.graphics;
			if( clear ) g.clear();
			g.beginFill(color, alpha);
			g.lineStyle(1, color);
			g.drawRect(x, y, width, height);
			g.endFill();
		}
		
		public static function getRandomInRange(low:Number, high:Number, unique:Boolean=false):Number
		{
			var r:Number = int(Math.random() * high-low) + low;
			
			if( !unique ) return r;
			
			//while ( r == lastRandomRange )
			while ( randomlyGeneratedNumbers.indexOf(r) >= 0 )
				r = int(Math.random() * high-low) + low;
			
			return r;
		}
		
		public static function getAngle(pointAX:Number, pointAY:Number, pointBX:Number, pointBY:Number, pureDegrees:Boolean=true):Number
		{
			//return angle
			var nYdiff:Number = (pointAY - pointBY);
			var nXdiff:Number = (pointAX - pointBX);
			var rad:Number = Math.atan2(nYdiff, nXdiff);
		
			var deg:Number = rad * 180 / Math.PI;
		
			//this will return a true 360 value
			if( pureDegrees ) deg = convertDeg(deg);
			return deg;
		}
		
		public static function convertDeg(d:Number):Number
		{
			var deg:Number = d < 0 ? 180 + (180-Math.abs(d)) : d;
			return deg;
		}
		
		public static function getDistance(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			return  Math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
		}
	}
}