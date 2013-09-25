class RPNCalculator
  def self.evaluate(expression)
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
      when "true"
        evaluation.push(true)
      when "false"
        evaluation.push(false)
      end
    end
    evaluation.pop
  end
end

