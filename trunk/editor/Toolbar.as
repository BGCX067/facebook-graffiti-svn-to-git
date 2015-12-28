package {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;
	import flash.text.*;
	import fl.controls.*;
	import fl.events.*;

	
	//import fl.motion.*;
	public class Toolbar
	{
		public var mcToolbarContainer:MovieClip;
		
		var editor:Editor;
		
		var toolbarWidth:int = 440;
		var toolbarHeight:int = 50;
		var toolbarLeft = 0;
		var toolbarTop = 0;
		
		var sldZoom:Slider;
		var sldOpacity:Slider;
		var sldWidth:Slider;
		
		public function Toolbar(editor:Editor)
		{	
			this.editor = editor;
		
			mcToolbarContainer = new MovieClip();
			mcToolbarContainer.x = toolbarLeft;
			mcToolbarContainer.y = toolbarTop;
			editor.addChild(mcToolbarContainer);
			
			sldZoom = new Slider;
			sldZoom.move(0, 20);
			mcToolbarContainer.addChild(sldZoom);		
			sldZoom.minimum = 1;
			sldZoom.maximum = 20;
			sldZoom.value = 5;
			sldZoom.liveDragging = true;
			sldZoom.addEventListener(SliderEvent.CHANGE, on_sldZoom_change);
			
			sldWidth = new Slider;
			sldWidth.move(100, 20);
			mcToolbarContainer.addChild(sldWidth);		
			sldWidth.minimum = 1;
			sldWidth.maximum = 20;
			sldWidth.value = 5;
			sldWidth.liveDragging = true;
			sldWidth.addEventListener(SliderEvent.CHANGE, on_sldWidth_change);
			
			sldOpacity = new Slider;
			sldOpacity.move(200, 20);
			mcToolbarContainer.addChild(sldOpacity);		
			sldOpacity.minimum = 1;
			sldOpacity.maximum = 100;
			sldOpacity.value = 100;
			sldOpacity.liveDragging = true;
			sldOpacity.addEventListener(SliderEvent.CHANGE, on_sldOpacity_change);
		}
		
		function on_sldZoom_change(evt:SliderEvent):void
		{
			editor.canvas.zoom = evt.value / 5;
		}
		
		function on_sldOpacity_change(evt:SliderEvent):void
		{
			editor.canvas.brush_opacity = evt.value / 100;
		}
		
		function on_sldWidth_change(evt:SliderEvent):void
		{
			editor.canvas.brush_width = evt.value;
		}
	}
}