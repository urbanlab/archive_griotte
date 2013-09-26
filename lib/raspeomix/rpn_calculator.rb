# RPNCalculator accepts a RPN "string", with space separated operands and
# operators, and evaluates the result

class RPNCalculator
  # Evaluates expression an returns the stack
  #
  # @param [String] expression RPN expression to evaluate (space separated)
  # @return [Array] Results stack
  def self.reduce_stack(expression)
    expression = expression.split
    operands = []
    evaluation = []

    expression.each do |x|
      case x
      when /\d/
        evaluation.push(x.to_f)
      # operations taking a parameter
      when "-", "/", "*", "+", "**", ">", ">=", "<", "<=", "|", "&", "modulo", "round"
        operands = evaluation.pop(2)
        evaluation.push(operands[0].send(x, operands[1]))
      # operations without additional parameter
      when "abs", "ceil", "floor"
        operands = evaluation.pop(1)
        evaluation.push(operands[0].send(x))
      # from Math lib
      when "sin", "cos", "tan", "asin", "acos", "atan", "sqrt"
        operands = evaluation.pop(1)
        evaluation.push(Math.send(x, operands[0]))
      when "true"
        evaluation.push(true)
      when "false"
        evaluation.push(false)
      end
    end
    evaluation
  end

  # Evaluates expression an returns the last element on the stack
  #
  # @param [String] expression RPN expression to evaluate (space separated)
  # @return [Float] Returns the last element of the evaluated stack
  def self.evaluate(expression)
    self.reduce_stack(expression).pop
  end
end

# If library is called directly, it can be used as a standalone calculator

if __FILE__ == $0
  puts RPNCalculator.evaluate(ARGV.join(" "))
end
