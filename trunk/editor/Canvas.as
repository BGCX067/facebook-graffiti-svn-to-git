package {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.net.*;
	import flash.text.*;
	import fl.controls.*;
	
	//import fl.motion.*;
	public class Canvas
	{
		protected var m_opacity:int;
		protected var m_brush_width:int;
		protected var m_brush_color:uint;
		protected var m_brush_opacity:Number;
		protected var m_currentLayerIndex:int;
		protected var m_zoom:Number;
		protected var m_strokeCoarseness:int = 20;
		protected var m_strokeTimeCoarseness:int = 100;
		
		public var mcCanvasContainer:MovieClip;
		public var mcCanvas:MovieClip;
		public var mcCanvasLayers:Array;
		public var ldPhoto:Loader;
		public var photoWidth:int, photoHeight:int;
		public var scrVertical:ScrollBar;
		public var scrHorizontal:ScrollBar;
		
		public var actions:Actions;
		public var editor:Editor;
		
		public var tags:Object;
		
		var canvasWidth:int = 440;
		var canvasHeight:int = 250;
		var canvasLeft:int = 0;
		var canvasTop:int = 50;
		var scrVerticalWidth:int = 15;
		var scrHorizontalHeight:int = 15;
		
		protected var lblLoadProgress:TextField;
		
		public function Canvas(editor:Editor)
		{	
			this.editor = editor;
		
			actions = new Actions(this);
			actions.canvas = this;
			mcCanvasContainer = new MovieClip();
			mcCanvasContainer.x = canvasLeft;
			mcCanvasContainer.y = canvasTop;
			editor.addChild(mcCanvasContainer);
			mcCanvas = new MovieClip();
			mcCanvas.x = 0;
			mcCanvas.y = 0;
			mcCanvasContainer.addChild(mcCanvas);
			
			mcCanvasLayers = new Array();
			zoom = 1;
			brush_width = 5;
			brush_opacity = 1;
			brush_color = Math.random()*0xBBD9F7;
			newLayer();
			loadPicture(editor.photo_url);
			newLayer();
			
			mcCanvas.addEventListener(MouseEvent.MOUSE_DOWN, on_mcCanvas_mouseDown);
			mcCanvas.addEventListener(MouseEvent.MOUSE_MOVE, on_mcCanvas_mouseMove);
			mcCanvas.addEventListener(MouseEvent.MOUSE_UP, on_mcCanvas_mouseUp);
			mcCanvas.stage.addEventListener(MouseEvent.MOUSE_UP, on_mcCanvas_mouseUp);
			
			
			// TODO: get all the FlashVars
			//loadPicture(flash vars . pic_url)
			// TODO: add scrollbars if necessary
		}
		
		public function loadPicture(pic_url:String)
		{
			ldPhoto = new Loader();
			ldPhoto.x = 0;
			ldPhoto.y = 0;
			ldPhoto.contentLoaderInfo.addEventListener(Event.OPEN, on_ldPhoto_open);
			ldPhoto.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, on_ldPhoto_progress);
			ldPhoto.contentLoaderInfo.addEventListener(Event.COMPLETE, on_ldPhoto_complete);

			var myRequest = new URLRequest(pic_url);
			ldPhoto.load(myRequest);
			mcCanvasLayers[currentLayerIndex].addChild(ldPhoto);
			
		}
		
		public function scrollTo(offset_fraction_x:Number, offset_fraction_y:Number)
		{
			var offset_in_pixels_x = (photoWidth * m_zoom - canvasWidth) * offset_fraction_x;
			var offset_in_pixels_y = (photoHeight * m_zoom - canvasHeight) * offset_fraction_y;
			var m:Matrix;
		
			for (var i = 0; i < mcCanvasLayers.length; ++i) {
					//mcCanvasLayers[i].x = -offset_in_pixels_x;
					//mcCanvasLayers[i].y = -offset_in_pixels_y;
				(m = new Matrix()).identity();
				m.translate(-offset_in_pixels_x, -offset_in_pixels_y);
				trace(offset_in_pixels_x, offset_in_pixels_y);
				mcCanvasLayers[i].transform.matrix = m;
			}
			
			// You can also add an m_border property later, to put a fixed border around the pics. Then we'd have
			// offset_in_pixels_y = m_border_height +  (loadedPicture.height * m_zoom - mcCanvasContainer.height + m_border_height)  * offset_fraction_y)
		}
		
		public function set zoom(factor:Number)
		{
			var m:Matrix; 
			
			for (var i = 0; i < mcCanvasLayers.length; ++i) {
				(m = new Matrix()).identity();
				m.scale(factor, factor);
				mcCanvasLayers[i].transform.matrix = m;
			}
			
			showScrollbarsIfNeeded();
			
			// TODO: change the zoom, handle the scrollbars
			// TODO: add scrollbars if necessary, otherwise hide them or disable them
			// To see how to zoom the layers, see scrollTo.
			// NOTE: We will need to SCALE all the graphics in the layers which already exist, when we scale the layers!
			m_zoom = factor;
		}
		
		public function get zoom():Number
		{
			return m_zoom;
		}
		
		public function get brush_width():int
		{
			return m_brush_width;
		}

		public function set brush_width(value:int):void
		{
			m_brush_width = value;
		}
		
		public function get brush_color():uint
		{
			return m_brush_color;
		}

		public function set brush_color(value:uint):void
		{
			m_brush_color = value;
		}
		
		public function get brush_opacity():Number
		{
			return m_brush_opacity;
		}

		public function set brush_opacity(value:Number):void
		{
			m_brush_opacity = value;
		}
		
		public function newLayer():int
		{			
			// TODO: delete all layers above current one
			var mc = new MovieClip();
			mc.x = 0;
			mc.y = 0;
			mc.graphics.clear();
			var m:Matrix;
			(m = new Matrix()).identity();
			m.scale(m_zoom, m_zoom);
			mc.transform.matrix = m;
			
			removeLayersAboveLayer(m_currentLayerIndex);
			
			mcCanvas.addChild(mc);
			m_currentLayerIndex = mcCanvasLayers.push(mc) - 1;
			return m_currentLayerIndex;
		}
		
		public function undoToLayer(index:int)
		{
			if (index < 0) {
				index = 0;
			}
			var i:int;
			if (index < m_currentLayerIndex) {
				for (i = m_currentLayerIndex; i > index; --i)
					mcCanvas.removeChild(mcCanvasLayers[i]);
				m_currentLayerIndex = index;
			} else if (index > m_currentLayerIndex) {
				for (i = m_currentLayerIndex + 1; i <= index; ++i)
					mcCanvas.addChild(mcCanvasLayers[i]);
				m_currentLayerIndex = index;
			}
			newLayer();
		}
		
		public function removeLayersAboveLayer(index:int)
		{
			if (index < 0)
				index = 0;
			if (index > mcCanvasLayers.length - 1)
				index = mcCanvasLayers.length - 1;
			if (index == mcCanvasLayers.length - 1)
				return;
			var i:int;
			for (i = mcCanvasLayers.length - 1; i > index; --i) {
				try {
					mcCanvas.removeChild(mcCanvasLayers[i]);
				} catch (e:Object) {
				}
				mcCanvasLayers.pop();
			}
			m_currentLayerIndex = index;
			
			// actions.removeLayersAboveLayer();
		}
		
		public function get currentLayerIndex() : int
		{
			return m_currentLayerIndex;
		}
		
		public function drawCurve(points:Array)
		{
			// TODO:
			// identify and use the movie clip at the current index
			// set the color, opacity etc. on that movie clip
			// moveTo and curveTo on that movie clip
			// points will be array of Numbers of the form x1, y1, x2, y2, ..., x_n, y_n
			// the Numbers will be of the same form as the tag coordinates, namely
			// x would be PERCENT of width and y would be PERCENT of height.
			// the numbers should be rounded to 1 decimal place, like so: 23.5
			// that gives us a resolution of 1000 x 1000 basically :-)
			
			/*
			// TODO: take this out
			// creates a red square
			var square:Shape = new Shape();
			square.graphics.beginFill(0x000000);
			square.graphics.drawRect(0, 0, 100, 100);
			
			var colorTransform:ColorTransform = square.transform.colorTransform;
			colorTransform.color = 0xFF0000;
			square.transform.colorTransform = colorTransform;
			
			addChild(square);
			*/
		}
		
		function drawText(x_percent:Number, y_percent:Number, caption:String)
		{
			// TODO: create a label and addChild it to the current layer,
			// where the current x_percent and y_percent
			// are in the top left of the text box.
		}
		
		function addTag(x_percent:Number, y_percent:Number, uid:uint, caption:String)
		{
			// Serialize the pair (x_percent, y_percent) into a string
			// tags[this string] = caption
		}
		
		function removeTag(x_percent:Number, y_percent:Number)
		{
			// Serialize the pair (x_percent, y_percent) into a string
			// remove tags[this string]
		}
		
		
		
		
		
		
		
		function on_ldPhoto_open(evt:Event):void {
			//lblLoadProgress = new TextField();
			//editor.addChild(lblLoadProgress);
		}
		
		function on_ldPhoto_progress(evt:ProgressEvent):void {
			//lblLoadProgress.text = "loaded:"+evt.bytesLoaded+" from "+evt.bytesTotal;
		}
		
		function on_ldPhoto_complete(evt:Event):void {
			photoWidth = evt.target.content.width;
			photoHeight = evt.target.content.height;
			mcCanvasLayers[0].addChild(ldPhoto);
			
			scrVertical = new ScrollBar();
			scrVertical.direction = ScrollBarDirection.VERTICAL;
			scrVertical.move(canvasWidth - scrVerticalWidth, 0);
			scrVertical.setSize(scrVerticalWidth, canvasHeight - scrHorizontalHeight);
			scrVertical.enabled = true;
			scrVertical.minScrollPosition = 0;
			scrVertical.maxScrollPosition = photoHeight * m_zoom;
			mcCanvasContainer.addChild(scrVertical);

			scrHorizontal = new ScrollBar();
			scrHorizontal.direction = ScrollBarDirection.HORIZONTAL;
			scrHorizontal.move(0, canvasHeight - scrHorizontalHeight);
			scrHorizontal.setSize(canvasWidth - scrVerticalWidth, scrHorizontalHeight);
			scrHorizontal.enabled = true;
			scrHorizontal.minScrollPosition = 0;
			scrHorizontal.maxScrollPosition = photoWidth * m_zoom;
			mcCanvasContainer.addChild(scrHorizontal);
			
			//editor.removeChild(lblLoadProgress);
		}
		
		private var canvasContainer_mouse_state = 0;
		
		private var mccc_lastLocalX:int;
		private var mccc_lastLocalY:int;
		private var mccc_strokeCount:int=0;
		private var mccc_strokePieces:int=0;
		private var mccc_startStrokeTime:Number=0;
		private var mccc_lastStrokeTime:Number=0;
		private var mccc_x_dir:int = 0, mccc_y_dir:int = 0;
		private var mccc_last_x_dir:int = 0;
		private var mccc_last_y_dir:int = 0;
		
		function on_mcCanvas_mouseDown(evt:MouseEvent):void
		{
			//undoToLayer(1);
			canvasContainer_mouse_state = 1;
			mccc_strokePieces = 0;
			mccc_startStrokeTime = (new Date()).getTime();
			
			mccc_last_x_dir = 0;
			mccc_last_y_dir = 0;
			
			var mc:MovieClip = mcCanvasLayers[currentLayerIndex];
			trace(m_brush_opacity);
			mc.graphics.lineStyle(m_brush_width, m_brush_color, m_brush_opacity);
			mc.graphics.moveTo(evt.localX, evt.localY);
		}
		
		function on_mcCanvas_mouseMove(evt:MouseEvent):void
		{
			var mc:MovieClip = mcCanvasLayers[currentLayerIndex];
			
			if ((Math.abs(evt.localX - mccc_lastLocalX) < m_strokeCoarseness )
				&& (Math.abs(evt.localY - mccc_lastLocalY) < m_strokeCoarseness)
				&& ((new Date()).getTime() - mccc_lastStrokeTime) < m_strokeTimeCoarseness)
			{
				return;
			}
			if (canvasContainer_mouse_state == 1)
			{
				if ((new Date()).getTime() - mccc_lastStrokeTime < m_strokeTimeCoarseness)
					mc.graphics.curveTo(mccc_lastLocalX + mccc_last_x_dir/2, mccc_lastLocalY + mccc_last_y_dir/2, evt.localX, evt.localY);
				else
					mc.graphics.lineTo(evt.localX, evt.localY);
				
				mccc_last_x_dir = evt.localX - (mccc_lastLocalX + mccc_last_x_dir/2);
				mccc_last_y_dir = evt.localY - (mccc_lastLocalY + mccc_last_y_dir/2);
				mccc_x_dir = evt.localX - mccc_lastLocalX;
				mccc_y_dir = evt.localY - mccc_lastLocalY;
			}
			mccc_lastStrokeTime = (new Date()).getTime();
			mccc_lastLocalX = evt.localX;
			mccc_lastLocalY = evt.localY;
			
			mccc_strokePieces++;
		}
		
		function on_mcCanvas_mouseUp(evt:MouseEvent):void
		{
			if (canvasContainer_mouse_state == 1)
			{
				newLayer();
				mccc_strokeCount++;
			}
			canvasContainer_mouse_state = 0;
		}
		
		function showScrollbarsIfNeeded()
		{
			if (photoWidth * m_zoom > canvasWidth)
			{
				trace('horizontal scroll');
				scrHorizontal.maxScrollPosition = photoWidth * m_zoom -canvasWidth;
			}
			else trace ('no horizontal scroll');
		}
	}
}