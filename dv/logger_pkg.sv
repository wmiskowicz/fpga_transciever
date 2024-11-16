package logger_pkg;

  typedef enum {DEBUG = 400, INFO = 300, WARNING = 200, ERROR = 100, FATAL = 0} e_msg_type;

  class logger;
    
    static int print_threshold;
    static int num_fatals;
    static int num_errors;
    static int num_warnings;
    static int num_infos;

    static function init(int print_threshold = 300);
      $timeformat(-9, 0, " ns", 20);
      logger::print_threshold = print_threshold;
    endfunction
    
    static function void log(input string msg, e_msg_type msg_type = INFO, string source = "");
      msg = $sformatf("%8s %t [%s]:\t%s\n", msg_type.name, $time, source, msg);
      if (msg_type <= print_threshold) begin
        $write(msg);
      end
      
      case(msg_type)
        INFO:     num_infos++;
        WARNING:  num_warnings++;
        ERROR:    num_errors++;
        FATAL:    num_fatals++;
      endcase
      
      if(msg_type == FATAL) begin
        summary();
        $finish();
      end
    endfunction
    
    static function void summary();      
      log($sformatf("----====  End of test. ====----"));
      log($sformatf("-- Fatals   = %8d", num_fatals));
      log($sformatf("-- Errors   = %8d", num_errors));
      log($sformatf("-- Warnings = %8d", num_warnings));
      log($sformatf("-- Infos    = %8d", num_infos));
      log($sformatf("----=======================----"));
      if(num_errors == 0 && num_fatals == 0)
        log("-- Test PASSED");
      else
        log("-- Test FAILED");
    endfunction
  
  endclass

  //Logger macros
  `define log_msg(msg,verb) logger::log((msg),(verb),$sformatf("%s(%0d)", `__FILE__, `__LINE__))
  `define log_info(msg)   `log_msg(msg,INFO)
  `define log_warn(msg)   `log_msg(msg,WARNING)
  `define log_err(msg)    `log_msg(msg,ERROR)
  `define log_fatal(msg)  `log_msg(msg,FATAL)

endpackage
