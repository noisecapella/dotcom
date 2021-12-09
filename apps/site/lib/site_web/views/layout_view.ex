defmodule SiteWeb.LayoutView do
  use SiteWeb, :view
  import Util.BreadcrumbHTML, only: [breadcrumb_trail: 1, title_breadcrumbs: 1]
  import SiteWeb.SearchHelpers, only: [desktop_form: 2]

  def bold_if_active(SiteWeb.Endpoint, _, text) do
    raw(text)
  end

  def bold_if_active(%Plug.Conn{} = conn, path, text) do
    requested_path = Enum.at(String.split(conn.request_path, "/"), 1)

    if requested_path == String.trim(path, "/") do
      raw("<strong>#{text}</strong>")
    else
      raw(text)
    end
  end

  defp has_styleguide_subpages?(%{params: %{"section" => "content"}}), do: true
  defp has_styleguide_subpages?(%{params: %{"section" => "components"}}), do: true
  defp has_styleguide_subpages?(_), do: false

  @spec styleguide_main_content_class(map) :: String.t()
  def styleguide_main_content_class(%{all_subpages: _}), do: " col-md-10"
  def styleguide_main_content_class(_), do: ""

  def get_page_classes(module, template) do
    module_class =
      module
      |> Module.split()
      |> Enum.slice(1..-1)
      |> Enum.join("-")
      |> String.downcase()

    template_class = template |> String.replace(".html", "-template")

    "#{module_class} #{template_class}"
  end

  def nav_link_content(conn),
    do: [
      {"Getting Around", "Transit Services, Plan Your Journey, Riding...",
       static_page_path(conn, :getting_around)},
      {"Fares", "Fares By Mode, Reduced Fares, Passes...", cms_static_page_path(conn, "/fares")},
      {"Contact Us", "Phone And Online Support, T-Alerts", customer_support_path(conn, :index)},
      {"More", "About Us, Business Center, Projects...", static_page_path(conn, :about)}
    ]

  def nav_link_content_redesign(conn),
    do: [
      %{menu_section: "Transit", sub_menus: [
        %{sub_menu_section: "Modes of Transit", links: [
          {"Subway", "/schedules/subway", :internal_link},
          {"Bus", "/schedules/bus", :internal_link},
          {"Commuter Rail", "/schedules/commuter-rail", :internal_link},
          {"Ferry", "/schedules/ferry", :internal_link},
          {"Paratransit (The RIDE)", "/accessibility/the-ride", :internal_link},
          {"All Schedules & Maps", "/schedules", :internal_link}
        ]},
        %{sub_menu_section: "Plan Your Journey", links: [
          {"Trip Planner", "/trip-planner", :internal_link},
          {"Service Alerts", "/alerts", :internal_link},
          {"Sign Up for Service Alerts", "https://alerts.mbta.com/", :external_link},
          {"Parking", "/parking", :internal_link},
          {"Bikes", "/bikes", :internal_link},
          {"User Guides", "/guides", :internal_link},
          {"Holidays", "/holidays", :internal_link},
          {"Accessibility", "/accessibility", :internal_link}
        ]},
        %{sub_menu_section: "Find a Location", links: [
          {"Find Nearby Transit", "/transit-near-me", :internal_link},
          {"MBTA Stations", "/stops", :internal_link},
          {"Destinations", "/destinations", :internal_link},
          {"Maps", "/maps", :internal_link}
        ]}
      ]},
      %{menu_section: "Fares", sub_menus: [
        %{sub_menu_section: "Fares Info", links: [
          {"Fares Overview", "/fares", :internal_link},
          {"Reduced Fares", "/fares/reduced", :internal_link},
          {"Transfers", "/fares/transfers", :internal_link},
          {"Fare Transformation", "/fare-transformation", :internal_link}
        ]},
        %{sub_menu_section: "Fares by Mode", links: [
          {"Subway Fares", "/fares/subway-fares", :internal_link},
          {"Bus Fares", "/fares/bus-fares", :internal_link},
          {"Commuter Rail Fares", "/fares/commuter-rail-fares", :internal_link},
          {"Ferry Fares", "/fares/ferry-fares", :internal_link}
        ]},
        %{sub_menu_section: "Pay Your Fare", links: [
          {"CharlieCard Store", "/fares/charliecard-store", :internal_link},
          {"Add Value to CharlieCard", "https://charliecard.mbta.com/", :external_link},
          {"Order Monthly Passes", "https://commerce.mbta.com/", :external_link},
          {"Get a CharlieCard", "/fares/charliecard#getacharliecard", :internal_link},
          {"Retail Sales Locations", "/fares/retail-sales-locations", :internal_link}
        ]},
        # special
        %{sub_menu_section: "Most popular fares"}
      ]},
      %{menu_section: "Contact", sub_menus: [
        %{sub_menu_section: "Customer Support", links: [
          {"Send Us Feedback", "/customer-support", :internal_link},
          {"View All Contact Numbers", "/customer-support#customer_support", :internal_link},
          {"Request Public Records", "https://massachusettsdot.mycusthelp.com/WEBAPP/_rs/supporthome.aspx?lp=3&COID=64D93B66", :external_link},
          {"Lost & Found", "/customer-support/lost-and-found", :internal_link},
          {"Language Services", "/language-services", :internal_link}
        ]},
        %{sub_menu_section: "Transit Police", links: [
          {"MBTA Transit Police", "/transit-police", :internal_link},
          {"See Something, Say Something", "/transit-police/see-something-say-something", :internal_link}
        ]},
        #special
        %{sub_menu_section: "Contact numbers"}
      ]},
      %{menu_section: "About", sub_menus: [
        %{sub_menu_section: "Get to Know Us", links: [
          {"Overview", "/mbta-at-a-glance", :internal_link},
          {"Leadership", "/leadership", :internal_link},
          {"History", "/history", :internal_link},
          {"Financials", "/financials", :internal_link},
          {"Public Meetings", "/events", :internal_link},
          {"Press Releases", "/news", :internal_link},
          {"MBTA Gift Shop", "http://www.mbtagifts.com/", :external_link},
          {"Policies & Civil Rights", "/policies", :internal_link},
          {"Safety", "/safety", :internal_link}
        ]},
        %{sub_menu_section: "Work with Us", links: [
          {"Careers", "/careers", :internal_link},
          {"Institutional Sales", "/pass-program", :internal_link},
          {"Business Opportunities", "/business", :internal_link},
          {"Innovation Proposals", "/innovation", :internal_link},
          {"Engineering Design Standards", "/engineering/design-standards-and-guidelines", :internal_link}
        ]},
        %{sub_menu_section: "Our Work", links: [
          {"Sustainability", "/sustainability", :internal_link},
          {"Building a Better T", "/projects/building-better-t-2020", :internal_link},
          {"Green Line Transformation", "/projects/green-line-transformation", :internal_link},
          {"Commuter Rail Positive Train Control", "/projects/commuter-rail-positive-train-control-ptc", :internal_link},
          {"Better Bus Project", "/projects/better-bus-project", :internal_link},
          {"All MBTA Improvement Projects", "/projects", :internal_link}
        ]}
      ]}
    ]
end
