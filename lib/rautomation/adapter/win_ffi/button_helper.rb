module RAutomation
  module Adapter
    module WinFfi
      module ButtonHelper
        extend self

        def set?
          control_hwnd = Functions.control_hwnd(@window.hwnd, @locators)

          if (@window.ms_accessibility_available?)
            Functions.checked? control_hwnd
          else
            fail "Using Win32 not yet implemented"
          end
        end

        # TODO call a windows function to do this without clicking
        def clear
          click if set? == true
        end

        # TODO call a windows function to do this without clicking
        def set(state_checked)
          click if state_checked == true
          clear if state_checked == false
        end
        
        alias_method :checked?, :set?

      end
    end
  end
end