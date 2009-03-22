$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

# 
# http://www.gigamonkeys.com/book/beyond-exception-handling-conditions-and-restarts.html
# 

require 'cond'
include Cond  # (optional)

class MalformedLogEntryError < StandardError
end

def parse_log_entry(text)
  if text =~ %r!\A\#!
    text.split
  else
    raise MalformedLogEntryError
  end
end

def find_all_logs
  [__FILE__]
end

def analyze_log(log)
  parse_log_file(log)
end

#
# (defun parse-log-file (file)
#   (with-open-file (in file :direction :input)
#     (loop for text = (read-line in nil nil) while text
#        for entry = (handler-case (parse-log-entry text)
#                      (malformed-log-entry-error () nil))
#        when entry collect it)))
#
def parse_log_file(file)
  File.open(file) { |input|
    input.each_line.inject(Array.new) { |acc, text|
      entry = handling do
        handle MalformedLogEntryError do
        end
        parse_log_entry(text)
      end
      entry ? acc << entry : acc
    }
  }
end

parse_log_file(__FILE__)

# 
# (defun parse-log-file (file)
#   (with-open-file (in file :direction :input)
#     (loop for text = (read-line in nil nil) while text
#        for entry = (restart-case (parse-log-entry text)
#                      (skip-log-entry () nil))
#        when entry collect it)))
# 
def parse_log_file(file)
  File.open(file) { |input|
    input.each_line.inject(Array.new) { |acc, text|
      entry = restartable do
        restart :skip_log_entry do
          leave
        end
        parse_log_entry(text)
      end
      entry ? acc << entry : acc
    }
  }
end

# remove this if you want to skip past here
Cond.debugger {
  parse_log_file(__FILE__)
}

# 
# (defun log-analyzer ()
#   (handler-bind ((malformed-log-entry-error
#                   #'(lambda (c)
#                       (invoke-restart 'skip-log-entry))))
#     (dolist (log (find-all-logs))
#       (analyze-log log))))
# 
def log_analyzer
  handling do
    handle MalformedLogEntryError do
      invoke_restart :skip_log_entry
    end
    find_all_logs.each { |log|
      analyze_log(log)
    }
  end
end

log_analyzer
