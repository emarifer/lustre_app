import gleam/dynamic
import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http

pub type Model {
  Model(count: Int, cats: List(Cat))
}

pub type Cat {
  Cat(id: String, url: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0, []), effect.none())
}

pub type Msg {
  UserIncrementCount
  UserDecrementCount
  ApiReturnedCats(Result(List(Cat), lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserIncrementCount -> #(Model(..model, count: model.count + 1), get_cat())
    UserDecrementCount -> #(
      Model(count: model.count - 1, cats: list.drop(model.cats, 1)),
      effect.none(),
    )
    ApiReturnedCats(Ok(api_cats)) -> {
      let assert [cat, ..] = api_cats
      #(Model(..model, cats: [cat, ..model.cats]), effect.none())
    }
    ApiReturnedCats(Error(_)) -> #(model, effect.none())
  }
}

fn get_cat() -> effect.Effect(Msg) {
  let decoder =
    dynamic.decode2(
      Cat,
      dynamic.field("id", dynamic.string),
      dynamic.field("url", dynamic.string),
    )

  let expect = lustre_http.expect_json(dynamic.list(decoder), ApiReturnedCats)

  lustre_http.get("https://api.thecatapi.com/v1/images/search", expect)
}

pub fn view(model: Model) -> element.Element(Msg) {
  let number = int.to_string(model.count)
  let count = fn() -> String {
    number
    <> case number {
      "1" -> " Cat"
      "0" | _ -> " Cats"
    }
  }

  html.div([attribute.class("w-full mx-auto flex flex-col gap-12")], [
    html.div([attribute.class("flex gap-4 mx-auto items-center mt-8")], [
      html.img([
        attribute.src("priv/static/img/left-cat.png"),
        attribute.class("w-12"),
      ]),
      html.h1([attribute.class("text-center text-2xl mb-4 mt-2 font-bold")], [
        element.text("Funny Cats"),
      ]),
      html.img([
        attribute.src("priv/static/img/right-cat.png"),
        attribute.class("w-12"),
      ]),
    ]),
    html.div(
      [attribute.class("w-full mx-auto flex justify-center items-center gap-8")],
      [
        html.button(
          [
            attribute.class("btn btn-outline btn-primary btn-sm"),
            attribute.title("Get cats"),
            event.on_click(UserIncrementCount),
          ],
          [element.text("+")],
        ),
        element.text(count()),
        html.button(
          [
            attribute.class("btn btn-outline btn-primary btn-sm"),
            attribute.title("Delete cats"),
            event.on_click(UserDecrementCount),
          ],
          [element.text("-")],
        ),
      ],
    ),
    element.keyed(
      html.div(
        [
          attribute.class(
            "w-full max-h-[60svh] overflow-y-auto mx-auto flex flex-wrap gap-4 scroller",
          ),
        ],
        _,
      ),
      list.map(model.cats, fn(cat) {
        #(
          cat.url,
          html.a([attribute.href(cat.url), attribute.target("_blank")], [
            html.img([
              attribute.class(
                "p-1 border-[1px] border-primary hover:border-warning ease-in duration-300 rounded object-cover h-48 w-80",
              ),
              attribute.src(cat.url),
            ]),
          ]),
        )
      }),
    ),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)

  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
// lustre.element(
//       html.div([], [
//         html.h1([], [element.text("Hello, world 😀!!")]),
//         html.figure([], [
//           html.img([attribute.src("https://cdn2.thecatapi.com/images/b7k.jpg")]),
//           html.figcaption([], [element.text("A cat!")]),
//         ]),
//       ]),
//     )

// html.div(
//   [],
//   list.map(model.cats, fn(cat) {
//     html.img([
//       attribute.src(cat.url),
//       attribute.width(400),
//       attribute.height(400),
//     ])
//   }),
// ),
