using Gee;

namespace Fabric.Applications.HueHi.Models {
	const string HUEADM = "hueadm";

	class HueAdmModel : Object {
		protected HueAdmModel() { }

		protected static Future<string> hueadm(string command) {
			var promise = new Promise<string>();

			new Thread<void*>("_hueadm", () => {
				string stdout = "";
				string stderr = "";
				int status = 0;

				var shell = "%s %s".printf(HUEADM, command);
				debug(" $ %s".printf(shell));

				// TODO handle non-zero status
				Process.spawn_command_line_sync(
					shell,
					out stdout,
					out stderr,
					out status
				);

				promise.set_value(stdout);

				return null;
			});

			return promise.future;
		}

		protected static Future<Json.Node> hueadm_json(string command) {
			return hueadm(command)
				.map<Json.Node>((result) => {
					Json.Parser parser = new Json.Parser();
					parser.load_from_data(result);
					return parser.get_root();
				})
			;
		}
	}

	class Group : HueAdmModel {
		/*
		  "3": {
			"name": "Kitchen",
			"lights": [
			  "3"
			],
			"sensors": [],
			"type": "Room",
			"state": {
			  "all_on": true,
			  "any_on": true
			},
			"recycle": false,
			"class": "Kitchen",
			"action": {
			  "on": true,
			  "bri": 71,
			  "alert": "select"
			}
		  },
		*/

		public string id { get; private set; }
		public string name { get; set; }
		public string group_type { get; set; }
		public string group_class { get; set; }
		public bool is_on { get; protected set; }
		public int brightness { get; protected set; }

		protected uint brightness_debounce_handle = 0;
		protected int desired_brightness = 0;

		private ArrayList<Scene> _scenes = new ArrayList<Scene>();
		public Gee.List<Scene> scenes {
			get {
				// Currently the lifecycle of the app is limited, so it's *okay* to not
				// refresh the scenes all the time.
				// Anyway they don't *change* other than being edited (renamed, lights changed)...
				// they are stateless in fleeting state (in-use or not)...
				if (_scenes.size == 0) {
					var ids = hueadm("scenes group=%s -H -oid".printf(Shell.quote(this.id)))
						.value
						.strip()
						.split("\n")
					;
					foreach (unowned string id in ids) {
						_scenes.add(Scene.get_from_id(id).value);
					}
				}

				return _scenes;
			}
		}

		public static Future<ArrayList<Group>> from_query(string type) {
			return hueadm_json("groups --json")
				.map<ArrayList<Group>>((result) => {
					Json.Object data = result.get_object();

					ArrayList<Group> ret = new ArrayList<Group>();
					data.foreach_member((_, id, node) => {
						if (type == "" || type == node.get_object().get_string_member("type")) {
							var group = new Group.from_object(id, node.get_object());
							ret.add(group);
						}
					});

					return ret;
				})
			;
		}

		protected Group() {}

		protected Group.from_object(string id, Json.Object obj) {
			this.id = id;
			_update_fields(obj);
		}

		protected void _update_fields(Json.Object obj) {
			lock (name) {
				name = obj.get_string_member("name");
			}
			lock (group_type) {
				group_type = obj.get_string_member("type");
			}
			lock (group_class) {
				group_class = obj.get_string_member("class");
			}
			var action = obj.get_object_member("action");
			lock (is_on) {
				is_on = action.get_boolean_member("on");
			}
			lock (brightness) {
				brightness = (int)action.get_int_member("bri");
			}
		}

		public void refresh() {
			new Thread<void*>("_group", () => {
				Json.Object data = hueadm_json("group --json %s".printf(Shell.quote(this.id))).value.get_object();
				_update_fields(data);

				return null;
			});
		}

		public void set_on(bool value) {
			new Thread<void*>("_group", () => {
				hueadm("group %s %s".printf(Shell.quote(id), value ? "on" : "off")).wait();
				refresh();
				return null;
			});
		}
		public void set_brightness_value(int value) {
			desired_brightness = value;
			if (brightness_debounce_handle != 0) {
				Source.remove(brightness_debounce_handle);
			}
			brightness_debounce_handle = Timeout.add_once(250, () => {
				brightness_debounce_handle = 0;
				new Thread<void*>("_group", () => {
					hueadm("group %s =%d".printf(Shell.quote(id), desired_brightness)).wait();
					refresh();
					return null;
				});
			});
		}
	}

	class Scene : HueAdmModel {
		/*
			{
			  "name": "Dim",
			  "type": "GroupScene", // LightScene or GroupScene
			  "group": "5",         // Group it applies to :)
			  "lights": [
				"1",
				"2",
				"3",
				"4",
				"5",
				"6"
			  ],
			  "owner": "d2233cf8-ba86-4a02-a3e0-706d8866f6cf", // App session that created it
			  "recycle": false,
			  "locked": false,
			  "appdata": {
				"version": 0,
				"data": "43zSl_r05"
			  },
			  "picture": "",
			  "lastupdated": "2023-09-21T18:06:03",
			  "version": 2,
			  "lightstates": {
				"1": {
				  "on": false
				},
				"2": {
				  "on": false
				},
				"3": {
				  "on": true,
				  "bri": 1
				},
				"4": {
				  "on": true,
				  "bri": 1
				},
				"5": {
				  "on": false
				},
				"6": {
				  "on": true,
				  "bri": 1
				}
			  }
			}
		*/
		public string id { get; set; }
		public string name { get; set; }
		public string scene_type { get; set; }
		public string group_id { get; set; }

		protected Scene() {}

		protected void _update_fields(Json.Object obj) {
			lock (name) {
				name = obj.get_string_member("name");
			}
			lock (scene_type) {
				scene_type = obj.get_string_member("type");
			}
			lock (group_id) {
				group_id = obj.get_string_member("group");
			}
		}

		protected Scene.from_object(string id, Json.Object obj) {
			this.id = id;
			_update_fields(obj);
		}
		public static Future<Scene> get_from_id(string id) {
			return hueadm_json("scene --json %s".printf(Shell.quote(id)))
				.map<Scene>((result) => {
					return new Scene.from_object(id, result.get_object());
				})
			;
		}

		public void refresh() {
			Json.Object data = hueadm_json("scene --json %s".printf(Shell.quote(this.id))).value.get_object();
			_update_fields(data);
		}

		public void activate() {
			if (scene_type == "GroupScene") {
				hueadm("group %s scene=%s".printf(Shell.quote(group_id), Shell.quote(id)));
			}
			else {
				error("Scene type “%s” is not handled yet...", scene_type);
			}
		}
	}
}
