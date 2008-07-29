package org.papervision3d.core.effects.view
{
	import flash.geom.ColorTransform;
	
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.core.proto.CameraObject3D;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.Viewport3D;

	public class ReflectionView extends BasicView
	{
		
		public var viewportReflection : Viewport3D; 
		public var cameraReflection : CameraObject3D;
		public var surfaceHeight : Number = 0; 
		
		public function ReflectionView(viewportWidth:Number=640, viewportHeight:Number=320, scaleToStage:Boolean=true, interactive:Boolean=false, cameraType:String="Target")
		{
			super(viewportWidth, viewportHeight, scaleToStage, interactive, cameraType);
			
			//set up reflection viewport and camera
			viewportReflection = new Viewport3D(viewportWidth, viewportHeight,scaleToStage, false); 


			// add the reflection viewport to the stage 
			addChild(viewportReflection); 
			setChildIndex(viewportReflection,0); 
			
			// flip it
			viewportReflection.scaleY = -1; 
			
			// and move it down
			viewportReflection.y += viewportHeight;  

			cameraReflection = new Camera3D(); 

    		// SAVING THIS CODE FOR LATER (may require transparent reflections... )
			/*var matrix:Array = new Array();
            matrix = matrix.concat([0.4, 0, 0, 0, 0]); // red
            matrix = matrix.concat([0, 0.4, 0, 0, 0]); // green
            matrix = matrix.concat([0, 0, 0.4, 0, 0]); // blue
            matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
			viewportReflection.filters = [new ColorMatrixFilter(matrix),new BlurFilter(8,8,1)]; 
			*/
			
			setReflectionColor(0.5,0.5,0.5); 
		}
		
		public override function singleRender():void
		{
			super.singleRender(); 
			
			cameraReflection.zoom = camera.zoom; 
			cameraReflection.focus = camera.focus; 
			if(camera is Camera3D)
			{
				Camera3D(cameraReflection).useCulling = Camera3D(camera).useCulling; 
			
			}
			cameraReflection.transform.copy(camera.transform);
			cameraReflection.y=-camera.y;
			cameraReflection.rotationX = -camera.rotationX;
			cameraReflection.rotationY = camera.rotationY;
			cameraReflection.rotationZ = -camera.rotationZ;
			
			cameraReflection.y+=surfaceHeight; 
			
			renderer.renderScene(scene, cameraReflection, viewportReflection);			

		}
		
		
		public function setReflectionColor(redMultiplier:Number=0, greenMultiplier:Number=0, blueMultiplier:Number=0, redOffset:Number=0, greenOffset:Number=0, blueOffset:Number=0): void
		{
			viewportReflection.transform.colorTransform = new ColorTransform(redMultiplier, greenMultiplier, blueMultiplier, 1, redOffset, greenOffset, blueOffset); 
			
		}
	
				
	}
}