# =======
# Imports
# =======

import os
import times
import strtabs
import xmltree
import sequtils
import strutils
import algorithm
import htmlparser


type
  ParseError* = object of Exception

# =========
# Functions
# =========

proc rssFeedContents*(root: string): seq[string] =
  var items = newSeq[string]()
  echo root
  for kind, path in walkDir(root):
    case kind
    of pcFile:
      if path.endsWith(".html") and (not path.endsWith("index.html")):
        let meta_tags = loadHtml(path).findAll("meta").filter(proc (tag:XmlNode): bool = tag.attrs.hasKey("name") and tag.attrs["name"] == "published")
        if len(meta_tags) > 0:
          items.add(path)
    else:
      discard
  return items

proc postDateCompare(a: string, b: string): int =
  let a_tags = loadHtml(a).findAll("meta").filter(proc (tag: XmlNode): bool = tag.attrs.hasKey("name") and tag.attrs["name"] == "dcterms.date")
  let b_tags = loadHtml(b).findAll("meta").filter(proc (tag: XmlNode): bool = tag.attrs.hasKey("name") and tag.attrs["name"] == "dcterms.date")
  if a_tags.len == 0:
    echo "publication date of '" & a & "' is missing!"
  if b_tags.len == 0:
    echo "publication date of '" & b & "' is missing!"
  if a_tags.len == 0 or b_tags.len == 0:
    raise newException(ParseError, "Both entries are missing the publication date field!")

  let a_date = a_tags[0].attrs["content"].parse("yyyy-MM-dd").toTime()
  let b_date = b_tags[0].attrs["content"].parse("yyyy-MM-dd").toTime()

  if a_date == b_date:
    return 0
  if a_date > b_date:
    return 1
  if a_date < b_date:
    return -1
  return 0

proc generateRssFeedXml*(base_url: string, export_dir: string, posts: seq[string]): string =
  var items = posts
  items.sort(postDateCompare, SortOrder.Descending)

  var feed_xml = <>rss(version="2.0")
  var channel_title = <>title(newText("Samantha Demi's Blog"))
  var channel_description = <>description(newText("Blog Feed"))
  var channel_link = <>link(newText(base_url))

  var channel = newXmlTree("channel", @[channel_title, channel_description, channel_link], newStringTable())
  feed_xml.add(channel)

  for post in items:
    let post_data = loadHtml(post)
    let post_metadata = post_data.findAll("meta")

    let found_titles = post_data.findAll("title")
    if found_titles.len == 0:
      raise newException(ParseError, "unable to locate a '<title>' tag for '" & post & "'!")

    let title_text = found_titles[0].innerText

    let found_descriptions = post_metadata.filter(proc (tag: XmlNode): bool = tag.attrs.hasKey("name") and tag.attrs["name"] == "summary")
    if found_descriptions.len == 0:
      raise newException(ParseError, "unable to locate a summary metadata tag for '" & post & "'!")

    let description_text = found_descriptions[0].attrs["content"]

    var title = <>title(newText(title_text))
    var description = <>description(newText(description_text))
    let post_url = post.replace(export_dir, base_url)
    var link = <>link(newText(post_url))

    var entry = <>item()
    entry.add(title)
    entry.add(description)
    entry.add(link)

    channel.add(entry)

  return xmlHeader & $feed_xml

#[
when isMainModule:
  let website_url = "http://pewpewthespells.com/"
  var items = rssFeedContents("~/Site/export/blog".expandTilde())
  items.sort(postDateCompare, SortOrder.Descending)
  echo generateRssFeedXml(website_url, items)
]#
