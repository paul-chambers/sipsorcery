begin
  # inbound call processing
  if sys.In
    if sys.IsMine(sys.FromSIPAccount.SIPUsername, sys.FromSIPAccount.SIPDomain)
      sys.Dial("#{sys.FromSIPAccount.SIPUsername}@local")
    end
  end
end
