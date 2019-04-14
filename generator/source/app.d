import std.stdio;
import dyaml;
import std.datetime;
import std.array;
import std.conv;
import std.regex;
import std.string;
import std.traits;
import std.meta;
import std.file;
import std.format;

struct Item {
  string title;
  string content;
  string year;
}

struct Definition {
  Item[] items;
  Link[] links;
  string html;
}

struct Link {
  string name;
  string target;
}

auto replaceLinks(Item[] items, Link[] links) {
  foreach(link; links) {
    auto href = format("<a href=\"%s\" target=\"_blank\"><b>%s</b></a>", link.target, link.name);
    foreach(ref item; items) {
      item.content = item.content.replace(link.name, href);
    }
  }
  return items;
}

auto replaceNewLines(Item[] items) {
  foreach(ref item; items)
    item.content = item.content.replace("\n","<br>");
}

auto decode(T)(ref Node node) {
  static if (is(T : Item[], Item)) {
    auto app = appender!(Item[]);
    foreach(Node i; node)
      app.put(i.decode!Item);
    return app.data;
  } else {
    T t;
    static foreach(idx, field; T.tupleof) {{
        enum string key = __traits(identifier, field);
        static if (!is(typeof(field) : string) && is(typeof(field) : A[], A)) {
          auto app = appender!(A[]);
          foreach(Node i; node[key])
            app.put(i.decode!A);
          t.tupleof[idx] = app.data;
        } else
          if (node.containsKey(key))
            t.tupleof[idx] = node[key].as!(typeof(field));
      }}
    return t;
  }
}

auto interpolate(T)(string html, auto ref T t) if (!is(T : string)){
  auto interpolator(Captures!(string) m) {
    string key = m[1].strip;
    static foreach(field; __traits(allMembers, T)) {{
        alias sym = AliasSeq!(__traits(getMember, T, field))[0];
        if (field == key) {
          static if (isFunction!(typeof(sym))) {
            static if (arity!sym == 0)
              return __traits(getMember, t, field)().to!string;
          } else
            return __traits(getMember, t, field).to!string;
        }
      }}
    throw new Error("Unknown field "~ key);
  }
  return html.replaceAll!(interpolator)(regex("\\{\\{%([^%]+)%\\}\\}"));
}

auto interpolate(string html, string content) {
  return html.replaceAll(regex("\\{\\{%([^%]+)%\\}\\}"), content);
}

auto render(ref Definition def) {
  auto app = appender!(string);
  foreach(item; def.items) {
    app.put(def.html.interpolate(item));
  }
  return app.data;
}
void main()
{
  auto node = Loader.fromFile("definitions/componist_tekst.yaml").load;
  auto def = node.decode!Definition;
  def.items.replaceLinks(def.links).replaceNewLines();
  std.file.write("../componist_tekst.html", readText("../componist_tekst.html.template").interpolate(def.render()));
}
