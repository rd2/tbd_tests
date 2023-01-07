# BSD 3-Clause License
#
# Copyright (c) 2020-2023, Denis Bourgeois & Dan Macumber
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "openstudio"

require "topolys"
require "oslg"
require "osut"
require "psi"
require "geo"
require "ua"
require "tbd_tests/version"

module TBD_Tests
  extend TBD

  TOL  = TBD::TOL
  TOL2 = TBD::TOL2
  DBG  = TBD::DEBUG  #   mainly to flag invalid arguments for devs (buggy code)
  INF  = TBD::INFO   #           informs TBD user of measure success or failure
  WRN  = TBD::WARN   # e.g. WARN users of 'iffy' .osm inputs (yet not critical)
  ERR  = TBD::ERR    #                            e.g. flag invalid .osm inputs
  FTL  = TBD::FATAL  #                     e.g. invalid TBD JSON format/entries
  NS   = "nameString" #                   OpenStudio IdfObject nameString method

  extend TBD
end
