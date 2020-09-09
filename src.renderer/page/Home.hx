package page;

import hxd.Key;

class Home extends Page {
	public static var ME : Home;

	var jPage(get,never) : js.jquery.JQuery; inline function get_jPage() return App.ME.jPage;

	public function new() {
		super();

		ME = this;
		App.ME.loadPage("home", {
			app: Const.APP_NAME,
			appVer: Const.getAppVersion(),
			jsonVer: Const.JSON_HEADER,
			docUrl: Const.DOCUMENTATION_URL,
			websiteUrl : Const.WEBSITE_URL,
			issueUrl : Const.ISSUES_URL,
			changelog: StringTools.htmlEscape( Const.CHANGELOG_MD ),
		});
		App.ME.setWindowTitle();

		// Buttons
		jPage.find(".load").click( function(ev) {
			onLoad();
		});

		jPage.find(".new").click( function(ev) {
			onNew();
		});

		jPage.find(".exit").click( function(ev) {
			App.ME.exit(true);
		});

		updateRecents();
	}

	function updateRecents() {
		var jRecentList = jPage.find("ul.recents");
		jRecentList.empty();

		var recents = App.ME.session.recentProjects;


		// Trim common path parts
		var trimmedPaths = recents.copy();
		if( trimmedPaths.length>1 ) {
			var splitPaths = trimmedPaths.map( function(p) return dn.FilePath.fromFile(p).getDirectoryAndFileArray() );

			var same = true;
			var trim = 0;
			while( same ) {
				for( i in 1...splitPaths.length )
					if( trim>=splitPaths[0].length || splitPaths[0][trim] != splitPaths[i][trim] ) {
						same = false;
						break;
					}
				if( same )
					trim++;
			}

			for(i in 0...trim)
			for(p in splitPaths)
				p.shift();

			trimmedPaths = splitPaths.map( function(p) return p.join("/") );
		}

		var i = recents.length-1;
		while( i>=0 ) {
			var p = recents[i];
			var li = new J('<li/>');
			li.appendTo(jRecentList);
			li.append( JsTools.makePath(trimmedPaths[i], C.fromStringLight(dn.FilePath.fromFile(trimmedPaths[i]).directory)) );
			li.click( function(ev) loadProject(p) );
			li.append( JsTools.makeExploreLink(p) );
			if( !JsTools.fileExists(p) )
				li.addClass("missing");
			i--;
		}
	}


	public function onLoad() {
		dn.electron.Dialogs.open([".json"], App.ME.getDefaultDir(), function(filePath) {
			loadProject(filePath);
		});
	}

	function loadProject(filePath:String) {
		if( !JsTools.fileExists(filePath) ) {
			N.error("File not found: "+filePath);
			App.ME.unregisterRecentProject(filePath);
			updateRecents();
			return false;
		}

		// Parse
		var json = null;
		var p = try {
			var raw = JsTools.readFileString(filePath);
			json = haxe.Json.parse(raw);
			led.Project.fromJson(json);
		}
		catch(e:Dynamic) {
			N.error( Std.string(e) );
			null;
		}

		if( p==null ) {
			N.error("Couldn't read project file!");
			return false;
		}

		// Open it
		App.ME.openEditor(p, filePath);
		N.success("Loaded project: "+dn.FilePath.extractFileWithExt(filePath));
		return true;
	}

	public function onNew() {
		dn.electron.Dialogs.saveAs([".json"], App.ME.getDefaultDir(), function(filePath) {
			var fp = dn.FilePath.fromFile(filePath);
			fp.extension = "json";

			var p = led.Project.createEmpty();
			p.name = fp.fileName;
			var data = JsTools.prepareProjectFile(p);
			JsTools.writeFileBytes(fp.full, data.bytes);

			N.msg("New project created: "+fp.full);
			App.ME.openEditor(p, fp.full);
		});
	}


	override function onKeyPress(keyCode:Int) {
		super.onKeyPress(keyCode);

		switch keyCode {
			case K.W, K.Q:
				if( App.ME.isCtrlDown() )
					App.ME.exit();
		}
	}

}
