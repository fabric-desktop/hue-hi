namespace Fabric.Applications.HueHi.Pages {
	class HomeLightCta : Gtk.Box {
		public const int ROOM = 1;
		public const int ZONE = 2;
		private int type;

		public HomeLightCta(int type) {
			this.type = type;

			var label = new Gtk.Label("") {
				hexpand = true,
				halign = Gtk.Align.FILL,
				valign = Gtk.Align.FILL,
			};
			append(label);

			if (this.type == ROOM) {
				label.label = "There are no rooms configured in your home.";
			}
			else {
				label.label = "There are no zones configured in your home.";
			}
		}

		construct {
			hexpand = true;
			halign = Gtk.Align.FILL;
			valign = Gtk.Align.FILL;
			set_name("HomeLightCta");
			add_css_class("hue-hi-cta");
		}
	}

	class HomeLightControl : Gtk.Box {
		private Gtk.Box top_bits;
		private Gtk.Box group_identity;
		private Gtk.Image icon;
		private Gtk.Scale light_scale;
		private Gtk.Label control_name;
		private Gtk.Switch toggle;

		public HomeLightControl(Models.Group group) {
			Object(
				orientation: Gtk.Orientation.VERTICAL,
				spacing: 0
			);

			top_bits = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				valign = Gtk.Align.CENTER,
			};
			top_bits.add_css_class("top-bits");

			group_identity = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
				valign = Gtk.Align.CENTER,
			};
			group_identity.add_css_class("top-bits");

			append(top_bits);
			top_bits.append(group_identity);

			icon = new Gtk.Image.from_icon_name("night-light");
			icon.halign = Gtk.Align.START;
			icon.add_css_class("-icon");
			icon.icon_size = 128;
			group_identity.append(icon);

			control_name = new Gtk.Label("");
			control_name.add_css_class("-name");
			control_name.hexpand = true;
			control_name.xalign = 0;
			group_identity.append(control_name);

			toggle = new Gtk.Switch() {
				valign = Gtk.Align.CENTER,
			};
			toggle.vexpand = false;
			top_bits.append(toggle);

			// The precise level control
			light_scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, 1, 255, 1);
			light_scale.round_digits = 0;
			append(light_scale);

			// Fill-in the controls
			control_name.label = group.name;
			toggle.active = group.is_on;
			light_scale.set_value(group.brightness);

			// Hook controls to the model
			group.notify["is-on"].connect(() => {
				toggle.set_active(group.is_on);
			});
			toggle.notify["active"].connect(() => {
				group.set_on(toggle.active);
				update_state();
			});

			group.notify["brightness"].connect(() => {
				light_scale.set_value(group.brightness);
			});
			light_scale.value_changed.connect(() => {
				if (!group.is_on) {
					group.set_on(true);
				}
				group.set_brightness_value((int)light_scale.get_value());
			});

			// The top bits go to the group view
			var gesture = new Gtk.GestureClick();
			gesture.pressed.connect((n_press, x, y) => {
				Fabric.UI.PagesContainer.instance.push(new Pages.Group(group));
			});
			group_identity.add_controller(gesture);

			update_state();
		}

		construct {
			hexpand = true;
			halign = Gtk.Align.FILL;
			valign = Gtk.Align.FILL;
			set_name("HomeLightControl");
			add_css_class("hue-hi-home-light-control");
		}

		private void update_state() {
			if (toggle.get_active()) {
				add_css_class("is-on");
			}
			else {
				remove_css_class("is-on");
			}
		}
	}

	/**
	 * The Home page (first page) only has a single instance.
	 *
	 * Also shows your *home*, in a logical sense too, heh.
	 */
	class Home : Fabric.UI.ScrollingPage {
		private Fabric.UI.MaybeEmptyBox rooms_container;
		private Fabric.UI.MaybeEmptyBox zones_container;
		private Gee.List<Models.Group> groups;
		private bool first_mapped = true;

		private Home() {}
		private static Home? _instance;
		public static Home instance {
			get {
				if (_instance == null) {
					_instance = new Home();
				}
				return _instance;
			}
		}

		construct {
			add_header("Home");

			groups = new Gee.ArrayList<Models.Group>();

			// TODO: have the "empty CTA" widget share duty of handling a loading state...

			append(Fabric.UI.Helpers.make_subheading("Rooms"));
			rooms_container = new Fabric.UI.MaybeEmptyBox();
			rooms_container.empty_widget = new HomeLightCta(HomeLightCta.ROOM);
			append(rooms_container);

			append(Fabric.UI.Helpers.make_subheading("Zones"));
			zones_container = new Fabric.UI.MaybeEmptyBox();
			zones_container.empty_widget = new HomeLightCta(HomeLightCta.ZONE);
			append(zones_container);

			fetch_data();

			map.connect(() => {
				refresh();
			});
		}

		public void fetch_data() {
			new Thread<void*>("_rooms", () => {
				rooms_container.loading = true;
				var rooms = Models.Group.from_query("Room").value;
				foreach(Models.Group room in rooms) {
					rooms_container.append(new HomeLightControl(room));
					groups.add(room);
				}
				rooms_container.loading = false;
				return null;
			});
			new Thread<void*>("_zones", () => {
				zones_container.loading = true;
				var zones = Models.Group.from_query("Zone").value;
				foreach(Models.Group zone in zones) {
					zones_container.append(new HomeLightControl(zone));
					groups.add(zone);
				}
				zones_container.loading = false;
				refresh();
				return null;
			});
		}

		public void refresh() {
			// Skip a useless first refresh
			if (first_mapped) {
				first_mapped = false;
				return;
			}

			foreach(Models.Group group in groups) {
				group.refresh();
			}
		}
	}
}
