
import os
import osproc
import strutils
import nativesockets
import strformat
import times

import uuids

proc key(key: string, value: string): string =
  result = fmt"$#:$#" % [key.capitalizeAscii(), value]

proc begin(entity: string): string =
  result = key("BEGIN", entity)

proc finish(entity: string): string =
  result = key("END", entity)

proc version(): string =
  result = key("VERSION", "2.0")

proc event(name: string, sdate, edate: DateTime): string =
  var body = newSeq[string]()
  body.add begin("VEVENT")
  body.add key("UID", $genUUID())
  body.add key("DTSTART", sdate.format("YYYYMMdd"))
  body.add key("DTEND", edate.format("YYYYMMdd"))
  body.add key("SUMMARY", name)

  let alarms = @["-P7D", "-P5D", "-P3D", "-P1D", "-P1H", "-P30M", "-P15M", "-P0M"]
  for alarm in alarms:
    body.add begin("VALARM")
    body.add key("TRIGGER;RELATIVE=END", alarm)
    body.add key("ACTION", "DISPLAY")
    body.add key("DURATION", "PT15M")
    body.add key("REPEAT", "0")
    body.add key("DESCRIPTION", "Event Alarm")
    body.add finish("VALARM")

  body.add finish("VEVENT")
  result = body.join("\r\n")

proc getCertificateExpiryCalendar*(): string =
  let cert_path =
    if getHostname().startsWith("Linode"): "/etc" / "letsencrypt" / "live" / "pewpewthespells.com-0001" / "fullchain.pem"
    else: "/home" / "demi" / "Desktop" / "pewpewthespells.com-0001" / "fullchain.pem"

  var body = newSeq[string]()
  body.add begin("VCALENDAR")
  body.add version()

  var subject: string
  var startDate: DateTime
  var endDate: DateTime

  let data = execProcess("openssl x509 -in " & cert_path & " -subject -startdate -enddate -noout")
  let entries = data.split("\n")
  for entry in entries:
    let pair = entry.split('=', 1)
    case pair[0]
    of "subject":
      subject = pair[1]
    of "notBefore":
      if pair[1][4] == ' ':
        startDate = parse(pair[1], "MMM  d HH:mm:ss yyyy 'GMT'", utc())
      else:
        startDate = parse(pair[1], "MMM d HH:mm:ss yyyy 'GMT'", utc())
    of "notAfter":
      if pair[1][4] == ' ':
        endDate = parse(pair[1], "MMM  d HH:mm:ss yyyy 'GMT'", utc())
      else:
        endDate = parse(pair[1], "MMM d HH:mm:ss yyyy 'GMT'", utc())
    else:
      discard

  body.add key("PRODID", "-//" & subject & "//Certificate Expiry Calendar//EN")
  body.add key("METHOD", "PUBLISH")
  body.add event("Certificate Expiry for pewpewthespells.com", startDate, endDate)
  body.add finish("VCALENDAR")

  result = body.join("\r\n")
