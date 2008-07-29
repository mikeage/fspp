/********

fspp - Flash Spherical Panorama Player
(c) 2008 Atanas Minev

This program is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.


Official site:
http://pan0.net/fspp



How to compile:
1. Install Adobe Flex SDK      http://www.adobe.com/products/flex/
2. unpack the source
3. use this command (enter the correct path to the compiler):
    /path/to/mxmlc -use-network=false fspp.as



ChangeLog:
--------------------------------------------------------------------------------------------------------------------
dd.mm.yy        version     description
--------------------------------------------------------------------------------------------------------------------
20.10.08        0.10        - fixed horizontal panorama mirroring issue
                        
                            - added commandline parameter:
                                mirrorImage - preserve old behaviour, e.g. image is mirrored horizontally,
                                this is for compatibility with old versions
                            
                            - added help panel
                            
                            - added pan0.net logo
                            
                            - added double click toggle fullscreen functionality
--------------------------------------------------------------------------------------------------------------------
29.07.08        0.03        - removed zoom, minZoom, maxZoom parameters, they are obsolete now
                
                            - added commandline parameters:
                                FOV    - set initial vertical field of view in degrees, default = 70
                                minFOV - set minimal FOV, default = 40
                                maxFOV - set maximal FOV, default = 120
                                
                            - field of view now is consistent, regardless of windows size or fullscreen mode
                            
                            - added load progress indicator
                            
                            - Papervision3D engine is now bundled with the source for easier maintaining
--------------------------------------------------------------------------------------------------------------------
09.06.08        0.02        added commandline parameters:

                            tesselation - tesselation of the pano sphere - default = 30, more is smoother, but slower

                            PA    - initial pitch angle - default = 0 degrees, points to horizon
                            minPA - min pitch angle - default = -90 degrees, camera points to nadir
                            maxPA - max pitch angle - default = 90 degrees, camera points to zenith
                            
                            zoom    - initial zoom - default = 1.5
                            minZoom - min camera zoom - default = 1
                            maxZoom - max camera zoom - default = 5
                            
                            allowFullScreen - allow fullscreen mode - default = true
--------------------------------------------------------------------------------------------------------------------
06.06.08        0.01        initial revision



********/


package  {
    import flash.display.*;
    import flash.geom.Point;
    import flash.ui.Keyboard;
    import flash.events.*;
    import flash.utils.*;
    import flash.text.*;
    import org.papervision3d.events.*;
    import org.papervision3d.cameras.*;
    import org.papervision3d.objects.primitives.Sphere;
    import org.papervision3d.core.math.Number3D;
    import org.papervision3d.core.geom.renderables.Triangle3D;
    import org.papervision3d.materials.BitmapFileMaterial;
    import org.papervision3d.view.BasicView;
    import gs.TweenLite;

    
    public class pan0 extends BasicView {
        ////////// constants
        private const DBL_CLICK_MILLISECONDS: Number = 300;
        
        ////////// parameters
        private var panoSrc: String = "pano.jpg";      
            
        private var tesselation: Number = 30;
    
        private var PA: Number = 0;                    
        private var minPA: Number = -90;                    
        private var maxPA: Number = 90;                     

        private var FOV: Number = 70;                    
        private var minFOV: Number = 40;                    
        private var maxFOV: Number = 120;       
            
        private var allowFullScreen: Boolean = true;
        private var mirrorImage: Boolean = false;

        
        ////////// variables
        private var txtLoadProgressFormat: TextFormat = new TextFormat();
        private var txtLoadProgress: TextField = new TextField();
        
        private var txtPan0netFormat: TextFormat = new TextFormat();
        private var txtPan0net: TextField = new TextField();
        
        private var txtHelpFormat: TextFormat = new TextFormat();
        private var txtHelp: TextField = new TextField();
        
        private var txtHelpMessageFormat: TextFormat = new TextFormat();
        private var txtHelpMessage: TextField = new TextField();
        
        private var lastMouseUp: Number = 0;
        private var clickCounter: Number = 0;
        private var lastClickPoint: Point;
        
        private var panoSphere: Sphere;
        private var material: BitmapFileMaterial;

        private var needsFastFrameRender: Boolean = false;
        private var needsSmoothFrameRender: Boolean = true;
        
        private var startPoint: Point;
        private var rotationXStart: Number = 0;
        private var rotationYStart: Number = 0;
        private var rotationXTarget: Number = 0;
        private var rotationYTarget: Number = 0;
        
        
        ////////// initialization stuff
        public function pan0() {
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.addEventListener(Event.RESIZE, onStageResize);
            super(stage.stageWidth, stage.stageHeight, true, true, CameraType.FREE);
            processParameters();
            init();
            startRendering();
        }
        
        private function processParameters(): void {
            if (loaderInfo.parameters.panoSrc)
                panoSrc= loaderInfo.parameters.panoSrc;
            
            if (loaderInfo.parameters.tesselation)
                tesselation= loaderInfo.parameters.tesselation;
            
            if (loaderInfo.parameters.PA)
                PA= loaderInfo.parameters.PA;
            
            if (loaderInfo.parameters.minPA)
                minPA= loaderInfo.parameters.minPA;
            
            if (loaderInfo.parameters.maxPA)
                maxPA= loaderInfo.parameters.maxPA;
            
            if (loaderInfo.parameters.FOV)
                FOV= loaderInfo.parameters.FOV;
            
            if (loaderInfo.parameters.minFOV)
                minFOV= loaderInfo.parameters.minFOV;
            
            if (loaderInfo.parameters.maxFOV)
                maxFOV= loaderInfo.parameters.maxFOV;
            
            if (loaderInfo.parameters.allowFullScreen)
                allowFullScreen= loaderInfo.parameters.allowFullScreen;
            
            if (loaderInfo.parameters.mirrorImage)
                mirrorImage= loaderInfo.parameters.mirrorImage;
        }
        
        private function init(): void {
            txtLoadProgressFormat.font= "Arial";
            txtLoadProgressFormat.size= 20;
            txtLoadProgress.textColor= 0xFFFFFF;
            txtLoadProgress.selectable= false;
            txtLoadProgress.defaultTextFormat= txtLoadProgressFormat;
            txtLoadProgress.autoSize= TextFieldAutoSize.CENTER;
            addChild(txtLoadProgress);
            
            txtPan0netFormat.font= "Arial";
            txtPan0netFormat.size= 16;
            txtPan0netFormat.bold= true;
            txtPan0net.textColor= 0xFFFFFF;
            txtPan0net.selectable= false;
            txtPan0net.defaultTextFormat= txtPan0netFormat;
            txtPan0net.autoSize= TextFieldAutoSize.CENTER;
            txtPan0net.text= "pan0.net";
            txtPan0net.blendMode = BlendMode.LAYER;
            txtPan0net.alpha= 0.45;
            addChild(txtPan0net);
            
            txtHelpFormat.font= "Arial";
            txtHelpFormat.size= 26;
            txtHelpFormat.bold= true;
            txtHelp.textColor= 0xFFFFFF;
            txtHelp.selectable= false;
            txtHelp.defaultTextFormat= txtHelpFormat;
            txtHelp.autoSize= TextFieldAutoSize.CENTER;
            txtHelp.text= "?";
            txtHelp.blendMode = BlendMode.LAYER;
            txtHelp.alpha= 0.55;
            txtHelp.addEventListener(MouseEvent.MOUSE_OVER, onTxtHelpMouseOver);
            txtHelp.addEventListener(MouseEvent.MOUSE_OUT, onTxtHelpMouseOut);
            txtHelp.addEventListener(MouseEvent.MOUSE_DOWN, onTxtHelpMouseDown);
            addChild(txtHelp);
            
            txtHelpMessageFormat.font= "Arial";
            txtHelpMessageFormat.size= 14;
            txtHelpMessage.textColor= 0xFFFFFF;
            txtHelpMessage.selectable= false;
            txtHelpMessage.multiline= true;
            txtHelpMessage.defaultTextFormat= txtHelpMessageFormat;
            txtHelpMessage.autoSize= TextFieldAutoSize.CENTER;
            txtHelpMessage.background= true;
            txtHelpMessage.backgroundColor= 0x000000;
            txtHelpMessage.blendMode = BlendMode.LAYER;
            txtHelpMessage.alpha= 0;
            txtHelpMessage.htmlText= 
                "<font size='16'><p align='center'>Mouse Controls</p></font>" +
                "<font size='10'><p></p></font>" +
                " <b>[press left button and drag]</b> - navigate panorama <br>" +
                " <b>[wheel up]</b> - zoom in<br>" +
                " <b>[wheel down]</b> - zoom out<br>" +
                " <b>[double click]</b> - toggle fullscreen mode<br><br><br>" +
                "<font size='16'><p align='center'>Keyboard Controls</p></font>" +
                "<font size='10'><p align='center'>not working in fullscreen mode due to Flash Player restrictions<br></p></font>" +
                " <b>[arrows]</b> - navigate panorama<br>" +
                " <b>[PgUp]</b> - zoom in<br>" +
                " <b>[PgDn]</b> - zoom out<br>" +
                " <b>[Home]</b> - fullscreen mode<br><br>" +
                " <b>[Esc]</b> - exit fullscreen mode (always works)<br><br>" +
                "<font size='11'><p align='center'>click anywhere in this box to close</p></font>";
            
            material = new BitmapFileMaterial(panoSrc);
            material.doubleSided = true;
            material.interactive = true;
            material.addEventListener(FileLoadEvent.LOAD_PROGRESS, onLoadProgress);
            material.addEventListener(FileLoadEvent.LOAD_COMPLETE, onLoadComplete);
            
            panoSphere= new Sphere(material, 30000, tesselation, tesselation);
            
            if (!mirrorImage)
                panoSphere.scaleZ= -1;
            
            scene.addChild(panoSphere);
            
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownEvent);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpEvent);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelEvent);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownEvent);
            
            camera.x = camera.y = camera.z = 0;
            camera.focus = 300;
            
            onStageResize();
        }



        
        ////////// event handlers
        override protected function onRenderTick(event: Event = null): void {
            camera.fov = FOV;
            
            if (needsFastFrameRender) {
                calcCameraRotation();
                super.onRenderTick(event);
            } 
            
            if (needsSmoothFrameRender) {
                material.smooth = true;
                super.onRenderTick(event);
                material.smooth = false;
                
                needsSmoothFrameRender = false;
            }
        }
        
        private function onStageResize(event: Event = null): void {
            needsSmoothFrameRender = true;
            
            try {
                getChildIndex(txtLoadProgress);
                txtLoadProgress.x= stage.stageWidth / 2;
                txtLoadProgress.y= stage.stageHeight / 2;
            }
            catch (e: ArgumentError) {
            }
            
            txtPan0net.x= stage.stageWidth - 77;
            txtPan0net.y= stage.stageHeight - 25;
            
            txtHelp.x= stage.stageWidth - 24;
            txtHelp.y= 0;
            
            try {
                getChildIndex(txtHelpMessage);
                txtHelpMessage.x= (stage.stageWidth - txtHelpMessage.textWidth) / 2;
                txtHelpMessage.y= (stage.stageHeight - txtHelpMessage.textHeight) / 2;
            }
            catch (e: ArgumentError) {
            }
        }
        
        private function onMouseDownEvent(e: MouseEvent): void {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEvent);
            startPoint = new Point(mouseX, mouseY);
            rotationYStart = camera.rotationY;
            rotationXStart = camera.rotationX;
            needsFastFrameRender = true;
        }

        private function onMouseMoveEvent(e: MouseEvent): void{
            rotationYTarget = rotationYStart - (startPoint.x - mouseX) / 2;
            rotationXTarget = rotationXStart - (startPoint.y - mouseY) / 2;
            needsFastFrameRender = true;
            lastMouseUp = 0;
        }

        private function onMouseUpEvent(e: MouseEvent): void{
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveEvent);
            needsFastFrameRender = false;
            needsSmoothFrameRender = true;
            
            var currentTime: Number= getTimer();
            var delta: Number= currentTime - lastMouseUp;

            clickCounter++;
            
            if (clickCounter % 2 == 0) {
                if ((delta > 0) && 
                    (delta <= DBL_CLICK_MILLISECONDS) && 
                    (lastClickPoint.x == mouseX) &&
                    (lastClickPoint.y == mouseY) &&
                    allowFullScreen)
                    toggleFullScreen();
                
                lastMouseUp = currentTime;
                lastClickPoint = new Point(mouseX, mouseY);
            }
        }
        
        private function onMouseWheelEvent(e: MouseEvent): void {
            FOV -= e.delta;
            
            if (FOV < minFOV)
              FOV = minFOV;
                    
            if (FOV > maxFOV)
              FOV = maxFOV;
              
            needsSmoothFrameRender = true;
            e.preventDefault();
        }
        
        private function onLoadProgress(event: FileLoadEvent): void {
            // txtLoadProgress.text = (event.bytesLoaded >> 10) + " KB of " + (event.bytesTotal >> 10) + " KB loaded";
            txtLoadProgress.text = (event.bytesLoaded >> 10) + " KB loaded";
        }
    
        private function onLoadComplete(event: FileLoadEvent): void {
            removeChild(txtLoadProgress);
            needsSmoothFrameRender = true;
        }
        
        private function onKeyDownEvent(event: KeyboardEvent): void {
            switch (event.keyCode) {
                case Keyboard.LEFT: 
                    rotationYTarget -= 2; 
                    calcCameraRotation(); 
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.RIGHT: 
                    rotationYTarget += 2; 
                    calcCameraRotation(); 
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.UP: 
                    rotationXTarget += 2; 
                    calcCameraRotation(); 
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.DOWN: 
                    rotationXTarget -= 2; 
                    calcCameraRotation(); 
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.PAGE_UP: 
                    FOV -= 5;
                    if (FOV < minFOV)
                      FOV = minFOV;
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.PAGE_DOWN: 
                    FOV += 5;
                    if (FOV > maxFOV)
                      FOV = maxFOV;
                    needsSmoothFrameRender = true; 
                    break;
                case Keyboard.HOME:
                    if ((stage.displayState == StageDisplayState.NORMAL) && allowFullScreen) {
                       stage.displayState = StageDisplayState.FULL_SCREEN;
                       needsSmoothFrameRender = true; 
                    }
                    break;
                case Keyboard.F1:
                    displayHelpMessage();
                    break;
            }
        }
        
        
        private function onTxtHelpMouseOver(e: MouseEvent): void {
            TweenLite.to(txtHelp, 0.4, {alpha: 1});
        }


        private function onTxtHelpMouseOut(e: MouseEvent): void {
            TweenLite.to(txtHelp, 0.4, {alpha: 0.55});
        }


        private function onTxtHelpMouseDown(e: MouseEvent): void {
            displayHelpMessage();
        }
        
        
        private function onTxtHelpMessageMouseDown(e: MouseEvent): void {
            TweenLite.to(txtHelpMessage, 0.4, {alpha: 0});
            setTimeout(removeHelpMessage, 400);
        }


        /////////////// utility stuff
        private function displayHelpMessage(): void {
            txtHelpMessage.addEventListener(MouseEvent.MOUSE_DOWN, onTxtHelpMessageMouseDown)
            addChild(txtHelpMessage);
            TweenLite.to(txtHelpMessage, 0.4, {alpha: 0.7});
            onStageResize();
        }
        
        private function removeHelpMessage(): void {
            removeChild(txtHelpMessage);
        }
        
        private function toggleFullScreen(): void {
            if (stage.displayState == StageDisplayState.NORMAL)
                stage.displayState= StageDisplayState.FULL_SCREEN;
            else
                stage.displayState= StageDisplayState.NORMAL;
            
            needsSmoothFrameRender= true;
        }
        
        private function calcCameraRotation(): void {
            camera.rotationY += (rotationYTarget - camera.rotationY) / 3;
            camera.rotationX += (rotationXTarget - camera.rotationX) / 3;
            
            if (camera.rotationX < minPA)
                camera.rotationX = minPA;
            
            if (camera.rotationX > maxPA)
                camera.rotationX = maxPA;
        }
    }
}