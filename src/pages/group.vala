namespace Fabric.Applications.HueHi.Pages {
	class GroupPageCta : Gtk.Box {
		public const int SCENE = 1;
		public const int LIGHT = 2;
		private int type;

		public GroupPageCta(int type) {
			this.type = type;

			var label = new Gtk.Label("") {
				hexpand = true,
				halign = Gtk.Align.FILL,
				valign = Gtk.Align.FILL,
			};
			append(label);

			if (this.type == SCENE) {
				label.label = "There are no scenes configured in this group.";
			}
			else {
				label.label = "There are no lights configured in this group.";
			}
		}

		construct {
			hexpand = true;
			halign = Gtk.Align.FILL;
			valign = Gtk.Align.FILL;
			set_name("GroupPageCta");
			add_css_class("hue-hi-cta");
		}
	}

	class SceneControl : Gtk.Box {
		private Models.Scene scene;
		private Gtk.Button button;
		public SceneControl(Models.Scene scene) {
			this.scene = scene;
			button = new Gtk.Button() {
				hexpand = true,
				halign = Gtk.Align.FILL,
				valign = Gtk.Align.FILL,
			};
			button.label = scene.name;
			button.clicked.connect(() => {
				scene.activate();
			});
			append(this.button);
		}
	}

	class Group : Fabric.UI.ScrollingPage {
		private Gtk.Switch toggle;
		private Models.Group group;
		private Fabric.UI.MaybeEmptyBox scenes_container;
		/*
		private Fabric.UI.MaybeEmptyBox lights_container;
		*/

		public Group(Models.Group group) {
			this.group = group;
			add_header("Group “%s”".printf(group.name));

			toggle = new Gtk.Switch();
			toggle.vexpand = false;
			toggle.valign = Gtk.Align.CENTER;
			toggle.set_active(group.is_on);
			header.actions.append(toggle);
			group.notify["is-on"].connect(() => {
				toggle.set_active(group.is_on);
			});
			toggle.notify["active"].connect(() => {
				group.set_on(toggle.active);
			});

			append(Fabric.UI.Helpers.make_subheading("Scenes"));
			scenes_container = new Fabric.UI.MaybeEmptyBox();
			scenes_container.loading = true;
			scenes_container.children_per_line = 4;
			scenes_container.empty_widget = new GroupPageCta(GroupPageCta.SCENE);
			append(scenes_container);

			new Thread<void*>("_scenes", () => {
				foreach(var scene in group.scenes) {
					scenes_container.append(new SceneControl(scene));
				}

				scenes_container.loading = false;
				return null;
			});

			// TODO light controls
			/*
			append(Fabric.UI.Helpers.make_subheading("Lights"));
			lights_container = new Fabric.UI.MaybeEmptyBox();
			lights_container.empty_widget = new GroupPageCta(GroupPageCta.LIGHT);
			append(lights_container);

			foreach(Models.Light light in group.lights) {
				lights_container.append(new LightControl(light));
			}
			*/
		}
	}
}
