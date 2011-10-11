module RAutomation
  module Adapter
    module MsUia
      class Control
        include WaitHelper
        include Locators

        # Creates the control object.
        # @note this method is not meant to be accessed directly
        # @param [RAutomation::Window] window this button belongs to.
        # @param [Hash] locators for searching the button.
        # @option locators [String, Regexp] :value Value (text) of the button
        # @option locators [String, Regexp] :class Internal class name of the button
        # @option locators [String, Fixnum] :id Internal ID of the button
        # @option locators [String, Fixnum] :index 0-based index to specify n-th button if all other criteria match
        # @see RAutomation::Window#button
        def initialize(window, locators)
          @window = window
          extract(locators)
        end

        #todo - replace with UIA version
        def hwnd
          Functions.control_hwnd(@window.hwnd, @locators)
        end


        def element
          puts "finding element with #{@locators.inspect}"


#          def uia_control(automation_id)
#          uia_window = UiaDll::element_from_handle(@window.hwnd) # finds IUIAutomationElement for given parent window
#          uia_element = UiaDll::find_child_by_id(uia_window, automation_id.to_s)
#          fail "Cannot find UIAutomationElement" if uia_element.nil?
#          uia_element
#        end

          case
            when @locators[:focus]
              puts "finding element by focus"
              uia_control = UiaDll::get_focused_element
              uia_control
            when @locators[:id]
              puts "finding element by id #{@locators[:id].to_s}"
              uia_window = UiaDll::element_from_handle(@window.hwnd)

              uia_control = UiaDll::find_child_by_id(uia_window, @locators[:id].to_s)

              raise UnknownElementException, "#{@locators[:id]} does not exist" if uia_control == nil
              uia_control
            #            when @locators[:pid]
            #              puts "finding element by pid #{@locators[:pid].to_i}"
            #              success = UiaDll::find_window_by_pid(@locators[:pid].to_i, element_pointer)
            #              puts element_pointer
            #              puts element_pointer.read_pointer
            #              raise UnknownElementException, "#{@locators[:id]} does not exist" if success == 0
            #              puts "element found:#{element_pointer.inspect}"
            #              element_pointer
            when @locators[:point]
              uia_control = UiaDll::element_from_point(@locators[:point][0], @locators[:point][1])
              raise UnknownElementException, "#{@locators[:point]} does not exist" if uia_control == nil
              uia_control
            else
              handle= hwnd
              raise UnknownElementException, "Element with #{@locators.inspect} does not exist" if (handle == 0) or (handle == nil)
              uia_control = UiaDll::element_from_handle(handle)
              uia_control
          end
        end


        #todo - replace with UIA version
        def click
          assert_enabled
          clicked = false
          wait_until do
            @window.activate
            @window.active? &&
                Functions.set_control_focus(hwnd) &&
                Functions.control_click(hwnd) &&
                clicked = true # is clicked at least once

            block_given? ? yield : clicked && !exist?
          end
        end

#        def exist?
#          begin
#            !!hwnd
#          rescue UnknownElementException
#            false
#          end
#        end


        def exist?
          begin
            if @locators[:point]
              !!UiaDll::element_from_point(@locators[:point][0], @locators[:point][1])
            else
              !!hwnd
            end
          rescue UnknownElementException
            false
          end
        end

        def enabled?
          !disabled?
        end

        #todo - replace with UIA version
        def disabled?
          Functions.unavailable?(hwnd)
        end

        #todo - replace with UIA version
        def has_focus?
          Functions.has_focus?(hwnd)
        end

        def set_focus
          assert_enabled
          uia_control = UiaDll::element_from_handle(hwnd)
          UiaDll::set_focus(uia_control)
        end

        def uia_control(automation_id)
          uia_window = UiaDll::element_from_handle(@window.hwnd) # finds IUIAutomationElement for given parent window
          uia_element = UiaDll::find_child_by_id(uia_window, automation_id.to_s)
          fail "Cannot find UIAutomationElement" if uia_element.nil?
          uia_element
        end

        def bounding_rectangle
#          control = element
          if @locators[:focus]
            puts "by focus"
            control = UiaDll::get_focused_element
          else
            control = UiaDll::element_from_handle(hwnd)
          end

          boundary = FFI::MemoryPointer.new :long, 4
          UiaDll::bounding_rectangle(control, boundary)

          boundary.read_array_of_long(4)
        end

        def visible?
          element = UiaDll::element_from_handle(hwnd)

          off_screen = FFI::MemoryPointer.new :int

          if UiaDll::is_offscreen(element, off_screen) == 0
            fail "Could not check element"
          end

#          puts "return #{off_screen.read_int}"
          if off_screen.read_int == 0
            return true
          end
          false
        end

        def matches_type?(clazz)
          get_current_control_type == clazz
        end

        def get_current_control_type(control = nil)
          uia_control = control

#          if control == nil
#            uia_control = element
#          end

          if control == nil
            if @locators[:point]
              uia_control = UiaDll::element_from_point(@locators[:point][0], @locators[:point][1])
            else
              uia_control = UiaDll::element_from_handle(hwnd)
            end
          end

          UiaDll::current_control_type(uia_control)
        end

        #I'm experimental! :)
        def new_control_type_method
          uia_control = UiaDll::element_from_point(@locators[:point][0], @locators[:point][1])
          UiaDll::current_control_type(uia_control)
        end

        def new_pid
          UiaDll::current_process_id(uia_control(@locators[:id]))
        end

        def control_name
          uia_control = UiaDll::element_from_point(@locators[:point][0], @locators[:point][1])
          element_name = FFI::MemoryPointer.new :char, UiaDll::get_name(uia_control, nil) + 1

          UiaDll::get_name(uia_control, element_name)
          element_name.read_string
        end

        alias_method :exists?, :exist?

        def assert_enabled
          raise "Cannot interact with disabled control #{@locators.inspect} on window #{@window.locators.inspect}!" if disabled?
        end
      end
    end
  end
end
