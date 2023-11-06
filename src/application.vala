namespace Fabric.Applications.HueHi {
	class Application : Fabric.UI.Application {
		construct {
			application_id = "fabric.applications.hue-hi";
		}

		protected override void activate() {
			Fabric.UI.PagesContainer.instance.push(Pages.Home.instance);
			add_styles_from_resource("/Fabric/Applications/HueHi/hue-hi.css");
			new Fabric.UI.PagedWindow() {
				title = "Hue Hi",
				application = this,
			}.present();
		}
	}

	public static int main(string[] args) {
		return (new Application()).run(args);
	}
}
