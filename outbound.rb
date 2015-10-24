AREA_CODE = '408'

SPEED_DIAL = {
  # directory assistance to (800) GOOG-411
  "411" => "+18004664411",
  # remap international emergency numbers to U.S. emergency
  "999" => "911",
  "112" => "911"
}

begin
  # outbound call processing.
  if sys.Out    # if outbound call

    dest = req.URI.User.to_s

    # translate speed dial numbers, if found
    dest = SPEED_DIAL[dest] || dest;

    # override the outbound caller ID if a *22 prefix is used
    callAs = case dest
    when /^\*223/ then "group"
    when /^\*224/ then "john"
    when /^\*225/ then "paul"
    when /^\*226/ then "george"
    when /^\*227/ then "ringo"
    else sys.FromSIPAccount.SIPUsername
    end

    if dest =~ /^*22[0-9]/
      dest = dest[4..-1]
    end

    case callAs
    when "group"  then sys.SetFromHeader("The Beatles",     "15105551212", nil)
    when "john"   then sys.SetFromHeader("John Lennon",     "14085551212", nil)
    when "paul"   then sys.SetFromHeader("Paul McCartney",  "16505551212", nil)
    when "george" then sys.SetFromHeader("George Harrison", "18315551212", nil)
    when "ringo"  then sys.SetFromHeader("Ringo Starr",     "14155551212", nil)
    else sys.Respond(603, "erm, who am I?")
    end

    # normalize dialed number to E.164
    case dest
    # local dialing
    when /^[2-9][0-9]{6}$/ then dest = "+1" + AREA_CODE + dest
    # North American Dialing Plan
    when /^1?([2-9][0-9]{9})$/ then dest = "+1" + $1
    # International dialing - North American or UK prefix
    when /^01[0-1]([1-9][0-9]+)$/ then dest = "+" + $1
    end

    sys.Log("Outbound call to #{dest}.")

    case dest

    # U.S. short numbers
    when /^[2-9]11$/ then sys.Dial("#{dest}@flowroute|#{dest}@voipms")

    # use sip to reach FreeConferenceCallHD 'numbers'
    when /^\+1712775[0-9]{4}$/ then sys.Dial("#{dest[2..-1]}@freeconferencecallhd|#{dest}@flowroute|#{dest}@voip.ms")

    # standard North America Dialing plan
    when /^\+1[2-9][0-9]{9}$/ then sys.Dial("#{dest}@flowroute|#{dest}@voip.ms")

    # route UK numbers to sipgate
    when /^\+44[1-9][0-9]+/ then
            sys.SetFromHeader("My Name", "accountsid", nil)
            sys.Dial("0#{dest[3..-1]}@sipgate")

    # other international numbers
    when /^\+[2-9][0-9]+$/ then sys.Dial("#{dest}@flowroute|#{dest}@voip.ms")

    # sip uri
    when /@/ then sys.Dial(dest)

    else sys.Respond(404, "no dial plan rule matches")

    end
  end
end
