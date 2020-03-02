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

import definition;
import ir;

auto interpolate(T)(string html, auto ref T t) if (!is(T : string)){
  auto interpolator(Captures!(string) m) {
    string key = m[1].strip;
    pragma(msg, T);
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

auto render(ref Record[] records, string html) {
  auto app = appender!(string);
  foreach(record; records) {
    app.put(html.interpolate(record));
  }
  return app.data;
}
void main()
{
  auto defs = loadDefinitions("definitions/componist_tekst.yaml");
  auto items = defs.toIr();
  std.file.write("../componist_tekst.html", readText("../componist_tekst.html.template").interpolate(render(items.nl, items.html)));
  std.file.write("../componist_tekst_en.html", readText("../componist_tekst_en.html.template").interpolate(render(items.en, items.html)));
}
