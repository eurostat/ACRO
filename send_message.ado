* warn.ado
* Send error message to users
* Created September 2020 by Felix Ritchie
*
* Last modified:
*  dd.mm.yy vnn by change
*

capture program drop send_message

program define send_message, rclass
  args message

  noisily display  "******************************************************************************"
  noisily display  `"*** `message'"'
  noisily display  "******************************************************************************"

end

