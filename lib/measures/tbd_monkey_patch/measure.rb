# MIT License
#
# Copyright (c) 2020-2024 Denis Bourgeois & Dan Macumber
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'openstudio-standards'

if OpenstudioStandards::VERSION >= '0.6.0' and OpenstudioStandards::VERSION <= '0.6.3'
  module OpenstudioStandards
    # Patch this method to work with local files for due to bug fixed in:
    # https://github.com/NREL/openstudio-standards/pull/1816
    module Weather
      def self.get_standards_weather_file_path(weather_file_name)
        # Define where the weather files lives
        top_dir = File.expand_path('../../..', File.dirname(__FILE__))
        weather_dir = File.expand_path("#{top_dir}/spec/files/epws")

        # Add Weather File
        unless (Pathname.new weather_dir).absolute?
          weather_dir = File.expand_path(File.join(File.dirname(__FILE__), weather_dir))
        end
        weather_file_path = File.join(weather_dir, weather_file_name)
        return weather_file_path
      end
    end
  end
end

class TBDMonkeyPatch < OpenStudio::Measure::ModelMeasure
  ##
  # Returns TBDMonkeyPatch identifier.
  #
  # @return [String] TBDMonkeyPatch identifier
  def name
    return "TBD Monkey Patch"
  end

  ##
  # Returns TBDMonkeyPatch description.
  #
  # @return [String] TBDMonkeyPatch description
  def description
    return "Patch bugs in OpenStudio Measures."
  end

  ##
  # Returns TBDMonkeyPatch modeler description.
  #
  # @return [String] TBDMonkeyPatch modeler description
  def modeler_description
    return "Check out rd2.github.io/tbd"
  end

  ##
  # Returns processed/validated TBDMonkeyPatch arguments.
  #
  # @param model [OpenStudio::Model::Model] a model
  #
  # @return [OpenStudio::Measure::OSArgumentVector] validated arguments
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new
    args
  end

  ##
  # Runs the TBDMonkeyPatch Measure.
  #
  # @return [Bool] whether TBDMonkeyPatch is successful
  def run(mdl, runner, args)
    super(mdl, runner, args)
    return true
  end
end

# register the measure to be used by the application
#TBDMonkeyPatch.new.registerWithApplication
