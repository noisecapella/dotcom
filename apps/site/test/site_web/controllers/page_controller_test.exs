defmodule SiteWeb.PageControllerTest do
  use SiteWeb.ConnCase
  import SiteWeb.PageController

  alias CMS.{
    Field.Link,
    Partial.Banner,
    Partial.Teaser,
    Partial.WhatsHappeningItem
  }

  alias Plug.Test
  alias SiteWeb.Plugs.Cookies

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Massachusetts Bay Transportation Authority"
    assert response_content_type(conn, :html) =~ "charset=utf-8"
  end

  test "sets a custom meta description", %{conn: conn} do
    conn = get(conn, "/")
    assert conn.assigns.meta_description
  end

  test "body gets assigned a js class", %{conn: conn} do
    [body_class] =
      default_conn()
      |> get(page_path(conn, :index))
      |> html_response(200)
      |> Floki.find("body")
      |> Floki.attribute("class")

    assert body_class == "no-js"
  end

  test "renders recommended routes if route cookie has a value", %{conn: conn} do
    cookie_name = Cookies.route_cookie_name()

    conn =
      conn
      |> Test.put_req_cookie(cookie_name, "Red|1|CR-Lowell|Boat-F4")
      |> get(page_path(conn, :index))

    assert Enum.count(conn.assigns.recently_visited) == 4

    assert [routes_div] =
             conn
             |> html_response(200)
             |> Floki.find(".c-recently-visited")

    assert Floki.text(routes_div) =~ "Recently Visited"

    for idx <- 0..3 do
      assert Floki.find(routes_div, "#recently-visited--#{idx}")
    end

    assert [_] = Floki.find(routes_div, ".c-svg__icon-red-line-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-bus-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-commuter-rail-default")
    assert [_] = Floki.find(routes_div, ".c-svg__icon-mode-ferry-default")
  end

  test "does not render recommended routes if route cookie has no value", %{conn: conn} do
    conn = get(conn, page_path(conn, :index))

    assert Map.get(conn.assigns, :recommended_routes) == nil
    refute html_response(conn, 200) =~ "Recently Visited"
  end

  test "split_whats_happening/1 returns first two if 2+ or 5+" do
    assert split_whats_happening([1, 2]) == {[1, 2], []}
    assert split_whats_happening([1, 2, 3, 4]) == {[1, 2], []}
    assert split_whats_happening([1, 2, 3, 4, 5]) == {[1, 2], [3, 4, 5]}
    assert split_whats_happening([1, 2, 3, 4, 5, 6]) == {[1, 2], [3, 4, 5]}
    assert split_whats_happening([1]) == {nil, nil}
  end

  test "adds utm params to url for news entries" do
    with_utm = add_utm_url(%Teaser{id: 1234, path: "/path", title: "title", type: :news_entry})

    assert %{
             path:
               "/path?utm_campaign=curated-content&utm_content=title&utm_medium=news&utm_source=homepage&utm_term=null"
           } = with_utm
  end

  test "adds utm params to url for what's happening" do
    promoted_with_utm =
      add_utm_url(%WhatsHappeningItem{link: %Link{url: "/path"}, title: "title"}, true)

    assert %{
             utm_url:
               "/path?utm_campaign=curated-content&utm_content=title&utm_medium=whats-happening&utm_source=homepage&utm_term=null"
           } = promoted_with_utm

    with_utm = add_utm_url(%WhatsHappeningItem{link: %Link{url: "/path"}, title: "title"}, false)

    assert %{
             utm_url:
               "/path?utm_campaign=curated-content&utm_content=title&utm_medium=whats-happening-secondary&utm_source=homepage&utm_term=null"
           } = with_utm
  end

  test "adds utm params to url for banner" do
    with_utm =
      add_utm_url(%Banner{
        link: %Link{url: "/path"},
        title: "title",
        routes: [%{id: "Green", mode: "subway", group: "line"}]
      })

    assert %{
             utm_url:
               "/path?utm_campaign=curated-content&utm_content=title&utm_medium=banner&utm_source=homepage&utm_term=green-line"
           } = with_utm
  end
end
