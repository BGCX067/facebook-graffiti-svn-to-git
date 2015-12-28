package
{
	import flash.display.MovieClip;
	import flash.display.*;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	
	import flash.events.*;
	import fl.events.*;
	
	import com.adobe.images.JPGEncoder;
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.shtif.web.MIMEConstructor;
	
	import com.adobe.serialization.json.JSON;
   
	import flash.system.System;
	import flash.net.*;
	import flash.text.TextField;
	
	import flash.events.*;
	import flash.utils.*;
	import fl.controls.*;
   
   
	public class Editor extends MovieClip
	{
		var fb_api_key = 'e1208a4d54d8870c04038c66f05539de';
		var fb_secret = 'ddd208917ddabc0a1c81556c05594108';
		var fb_user = root.loaderInfo.parameters['fb_sig_user'];
		var fb_session_key = root.loaderInfo.parameters['fb_sig_session_key'];
		var base_call_id = root.loaderInfo.parameters['base_call_id'];
		
		var photo_pid:String;
		var photo_aid:String;
		var tags_json:String;
		var tags_array:Array;
		var by_uid:String;
		var graffiti_content:String;
		
		var photo_url:String;
		var photo_proxy_url:String;
		var post_url:String;
		var report_result_url:String;
		var edit_graffiti_id:String;
		
		var ldPhoto:Loader;
		var myRequest:URLRequest;
		
		var mcContainer:MovieClip;
		var mcPhoto:MovieClip;
		
		var loadProgress_txt:TextField;
		
		var toolbar:Toolbar;
		var canvas:Canvas;
		
		public function Editor() {
			
			//lblSaving.visible = false;
			photo_pid = root.loaderInfo.parameters.photo_pid;
			photo_aid = root.loaderInfo.parameters.photo_aid;
			tags_json = root.loaderInfo.parameters.tags_json;
			if (tags_json)
				tags_array = (JSON.decode(tags_json) as Array);
			by_uid = root.loaderInfo.parameters.by_uid;
			graffiti_content = root.loaderInfo.parameters.graffiti_content;
			
			photo_url = root.loaderInfo.parameters.photo_url;
			photo_proxy_url = root.loaderInfo.parameters.photo_proxy_url;
			post_url = root.loaderInfo.parameters.post_url;
			report_result_url = root.loaderInfo.parameters.report_result_url;
			edit_graffiti_id = root.loaderInfo.parameters.edit_graffiti_id;

			if (!photo_url)
				photo_url = 'http://photos-e.ak.facebook.com/photos-ak-sf2p/v136/41/26/503622528/n503622528_220404_9097.jpg';
				
			// TODO: Put this all into a Toolbar class
			toolbar = new Toolbar(this);			
			canvas = new Canvas(this);
			
			return;
			
			ldPhoto = new Loader();
			myRequest = new URLRequest(photo_url);
			
			loadProgress_txt = new TextField();
			
			ldPhoto.x = 0;
			ldPhoto.y = 0;
			
			ldPhoto.contentLoaderInfo.addEventListener(Event.OPEN, showPreloader);
			ldPhoto.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, showProgress);
			ldPhoto.contentLoaderInfo.addEventListener(Event.COMPLETE, showLoadResult);
			
			ldPhoto.load(myRequest);
			
			//btnSave.addEventListener(MouseEvent.CLICK, onSave);
			//btnDraw.addEventListener(MouseEvent.CLICK, onDraw);
		}
		
		function showPreloader(evt:Event):void {
			addChild(loadProgress_txt);
		}
		
		function showProgress(evt:ProgressEvent):void {
			loadProgress_txt.text = "loaded:"+evt.bytesLoaded+" from "+evt.bytesTotal;
		}
		
		function showLoadResult(evt:Event):void {
			mcContainer = new MovieClip();
			mcContainer.x = 0;
			mcContainer.y = 0; //toolbar_height;
			addChild(mcContainer);
			
			mcPhoto = new MovieClip();
			mcPhoto.x = 0;
			mcPhoto.y = 0;
			mcContainer.addChild(mcPhoto);
			mcPhoto.addChild(ldPhoto);
			
			removeChild(loadProgress_txt);
		}
		
		function onDraw(evt:Event) {
			switch(evt.currentTarget.label) {
				case "Draw":
					drawOnTop(mcContainer, 0);
					break;
			}  
		}
		
		function onSave(evt:Event) {
			switch(evt.currentTarget.label) {
			
				case "Save":
					drawOnTop(mcContainer, 100);
					saveAndUpload(mcContainer);
					break;
			}  
		}
		
		function drawOnTop(mcContainer:MovieClip, offset:int)
		{
			var mc2:MovieClip = new MovieClip();
			mcContainer.addChild(mc2);
			mc2.graphics.lineStyle(0, 0x0000FF, 100);
			mc2.graphics.beginFill(0xFF0000);
			mc2.graphics.moveTo(0, 100+offset);
			mc2.graphics.curveTo(0,200,100,200+offset);
			mc2.graphics.curveTo(200,200,200,100+offset);
			mc2.graphics.curveTo(200,0,100,0+offset);
			mc2.graphics.curveTo(0,0,0,100+offset);
			mc2.graphics.endFill();
		}
		
		function saveAndUpload(mcContainer:MovieClip)
		{
			// First, send a request (using sendToURL)
			// to our web service, with the contents of the graffiti,
			// signed with the signature, etc. :)
			
			// THEN:
			
			// Replace photo with the one from proxy url,
			// so that we can get at its pixels.
			var photo_proxy_request:URLRequest = new URLRequest(photo_proxy_url);
			var ld2:Loader = new Loader();
			ld2.load(photo_proxy_request);
			mcPhoto.removeChild(ldPhoto);
			mcPhoto.addChildAt(ld2, 0);
			addChild(loadProgress_txt);
			
			ld2.contentLoaderInfo.addEventListener(Event.OPEN, showPreloader);
			ld2.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, showProgress);
			ld2.contentLoaderInfo.addEventListener(Event.COMPLETE, onLd2Complete);
		}
		
		function onLd2Complete(evt:Event):void {
			removeChild(loadProgress_txt);
			
			// TODO: go through display list from bottom to top,
			// and add all the stuff on top of the proxy image
			// then take a screenshot, like we do below:
		
			// set up a new bitmapdata object that matches the dimensions of the stage;
			var bmd:BitmapData = new BitmapData( mcContainer.width, mcContainer.height );
			// draw the bitmapData from the mcContainer to the bitmapData object;
			bmd.draw( mcContainer );
			upload_photo(bmd);
		}
		
		var upload_photo_calls_count:int = 0;
		
		function upload_photo (bmpData: BitmapData): void 
		{
			
			
			//Converting BitmapData into a JPEG-encoded ByteArray		
			var jpgObj: JPGEncoder = new JPGEncoder(98);
			var imageBytes: ByteArray = jpgObj.encode (bmpData);
			imageBytes.position = 0;
			
			// TODO: implement facebook call!
			var args = new Object();
			args['method'] = 'facebook.photos.upload';
			args['v'] = '1.0';
			args['api_key'] = fb_api_key;
			args['session_key'] = fb_session_key;
			++upload_photo_calls_count;
			args['call_id'] = base_call_id + upload_photo_calls_count;
			args['caption'] = 'http://yahoo.com';
			args['aid'] = '';
			args['sig'] = getSig(args, fb_secret);
		
			var boundary: String = 'SomeTextWeWillNeverSee7d76d1b56035e';
			var header1: String  = ''; //'Content-Type: multipart/form-data; boundary=' + boundary + '\r\n';
			header1 += 'MIME-version: 1.0\r\n\r\n';
			header1 += '--' + boundary + '\r\n';
			for (var k in args)
			{
				header1 += 'Content-Disposition: form-data; name="' + k + '"\r\n\r\n';
				header1 += args[k]+'\r\n';
				header1 += '--' + boundary + '\r\n';
			}
			header1 += 'Content-Disposition: form-data; filename="edited_photo.jpg"\r\n';
			header1 += 'Content-Type: image/jpg\r\n\r\n';
		
				//In a normal POST header, you'd find the image data here
				
			var header2: String =	'--' + boundary + '--\r\n';
			//Encoding the two string parts of the header
			var headerBytes1: ByteArray = new ByteArray();
			headerBytes1.writeMultiByte(header1, "ascii");
			
			var headerBytes2: ByteArray = new ByteArray();
			headerBytes2.writeMultiByte(header2, "ascii");
					
				//Creating one final ByteArray
			var mime:MIMEConstructor = new MIMEConstructor();
			mime.setBoundary(boundary);
			for(var j:String in args)
				mime.writePostData(j, args[j]);
			mime.writeFileData("photo", imageBytes); 
			mime.closePostData();
		
			
			var urlreq:URLRequest = new URLRequest();
			urlreq.method = URLRequestMethod.POST;
			urlreq.contentType = "multipart/form-data; boundary=" + mime.getBoundary();
			urlreq.data = mime.getPostData();
			urlreq.url = post_url;
			
			
			loadProgress_txt.multiline = true;
			loadProgress_txt.text = 'Image Bytes: ';
			loadProgress_txt.appendText(imageBytes.toString());
			addChild(loadProgress_txt);
		
				/*
			var sendBytes: ByteArray = new ByteArray();
			sendBytes.writeBytes(headerBytes1, 0, headerBytes1.length);
			sendBytes.writeBytes(imageBytes, 0, imageBytes.length);
			sendBytes.writeBytes(headerBytes2, 0, headerBytes2.length);
				
			var request: URLRequest = new URLRequest(post_url);
			request.data = sendBytes;
			request.method = URLRequestMethod.POST;
			request.contentType = "multipart/form-data; boundary=" + boundary;
				*/
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, uploadCompleted);
			
			try {
				urlLoader.load(urlreq);
			} catch (error: Error) {
				trace("Unable to load requested document.");
			}
			
		}
		
		function uploadCompleted (e: Event) {
			loadProgress_txt.text = e.target.data;
			
			// REPORT:
			// in addition to the response_text,
			// send the tags_array and the graffiti data!
			
			var urlreq:URLRequest = new URLRequest(report_result_url);
			urlreq.method = URLRequestMethod.POST;
			var variables:URLVariables = new URLVariables();
			variables.response_text = e.target.data;
			variables.tags_json = tags_json;
			variables.graffiti_content = '{some content}';
			variables.edit_graffiti_id = edit_graffiti_id;
			variables.photo_pid = photo_pid;
			variables.photo_aid = photo_aid;
			variables.by_uid = by_uid;
			urlreq.data = variables;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			urlLoader.addEventListener(Event.COMPLETE, reportCompleted);
			
			try {
				urlLoader.load(urlreq);
				//sendToURL(urlreq);
			} catch (e:Error) {
				
			}
			
		//	var xml_data:XML = XML(e.target.data);
		//	loadProgress_txt.text = xml_data.child('pid').length.toString() + ' ';
		//	loadProgress_txt.text += xml_data.child('aid')[0].text() + ' ';
		//	loadProgress_txt.text += xml_data.child('created')[0].text();
		}
		
		function reportCompleted (e: Event) {
			var url:String = e.target.data;
			if (url.length > 0) {
				var connection:LocalConnection = new LocalConnection(); 
				var connectionName:String = LoaderInfo(this.root.loaderInfo).parameters.fb_local_connection; 
				function callFBJS(methodName:String, ... parameters):void { 
					if (connectionName) { 
						connection.send(connectionName, "callFBJS", methodName, parameters); 
					} 
				} 
				loadProgress_txt.text = url;
				callFBJS("document.setLocation", url);
			}
		//		navigateToURL(new URLRequest(url), 'iframe_confirm');
		}
		
		function getSig(args:Object, secret:String):String
		{
			var a:Array = [];
			
			for( var p:String in args )
			{
				var arg = args[p];
				if( p !== 'sig' && !(arg is ByteArray))
					a.push( p + '=' + arg.toString() );
			}
			
			a.sort();
			
			var s:String = '';
			for( var i:Number = 0; i < a.length; i++ )
				s += a[i];
			s += secret;
			
			return MD5.hash( s );
		}
   }
}
