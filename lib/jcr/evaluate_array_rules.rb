# Copyright (c) 2015 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'ipaddr'
require 'time'
require 'addressable/uri'
require 'addressable/template'
require 'email_address_validator'
require 'big-phoney'

require 'jcr/parser'
require 'jcr/map_rule_names'
require 'jcr/check_groups'
require 'jcr/evaluate_rules'

module JCR

  def self.evaluate_array_rule jcr, rule_atom, data, mapping

    # if the data is not an array
    return Evaluation.new( false, "#{data} is not an array at #{jcr} from #{rule_atom}") unless data.is_a? Array

    if jcr.is_a? Hash
      jcr = [ jcr ]
    end

    # if the array is zero length and there are zero sub-rules (it is suppose to be empty)
    return Evaluation.new( true, nil ) if jcr.is_a?( Parslet::Slice ) && data.length == 0
    # if the array is not empty and there are zero sub-rules (it is suppose to be empty)
    return Evaluation.new( false, "Non-empty array at #{jcr} from #{rule_atom}" ) if jcr.is_a?( Parslet::Slice ) && data.length != 0

    retval = nil
    array_index = 0

    jcr.each do |rule|

      # short circuit logic
      if rule[:choice_combiner] && retval && retval.success
        return retval # short circuit
      elsif rule[:sequence_combiner] && retval && !retval.success
        return retval # short circuit
      end

      repeat_min = 1
      repeat_max = 1
      if rule[:repetition_min]
        repeat_min = rule[:repetition_min]
      end
      if rule[:repetition_max]
        repeat_max = rule[:repetition_max]
      end

      for i in 0..repeat_min do
        if array_index == data.length
          return Evaluation.new( false, "array is not large enough for #{jcr} from #{rule_atom}" )
        else
          retval = evaluate_rule( rule, rule_atom, data, mapping )
          array_index = array_index + 1
          break unless retval.success
        end
      end
      if !retval || retval.success
        for i in repeat_min..repeat_max do
          break if array_index == data.length
          e = evaluate_rule( rule, rule_atom, data, mapping )
          array_index = array_index + 1
          break unless retval.success
        end
      end

    end

    return retval
  end

end
