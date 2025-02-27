# Loads the files that are used by ruby-dicom.
#
# The following classes are meant to be used by users of ruby-dicom:
# * DObject - for reading, manipulating and writing DICOM files.
# * Element, Sequence, Item, Parent, Elemental - users who wish to interact with
#   their DICOM objects will use these classes/modules.
# * ImageItem - Image related methods are found in this class.
# * DClient - for client side network communication, like querying, moving & sending DICOM files.
# * DServer - for server side network communication: Setting up your own DICOM storage node (SCP).
# * Anonymizer - a convenience class for anonymizing your DICOM files.
#
# The rest of the classes visible in the documentation generated by YARD are
# in principle 'private' classes, which are mainly of interest to developers.

# Standard library dependencies:
require 'json'

# Gem specific extensions:
require_relative 'dicom/extensions/array_extensions'
require_relative 'dicom/extensions/hash_extensions'
require_relative 'dicom/extensions/string_extensions'

# General module features/settings:
require_relative 'dicom/general/version'
require_relative 'dicom/general/constants'
require_relative 'dicom/general/configuration'
require_relative 'dicom/general/variables'
require_relative 'dicom/general/methods'

# Core library:
# Super classes/modules:
require_relative 'dicom/image_processor'
require_relative 'dicom/parent'
require_relative 'dicom/image_item'
require_relative 'dicom/elemental'
require_relative 'dicom/elemental_parent'
# Subclasses and independent classes:
require_relative 'dicom/d_object'
require_relative 'dicom/d_read'
require_relative 'dicom/d_write'
require_relative 'dicom/element'
require_relative 'dicom/item'
require_relative 'dicom/sequence'
require_relative 'dicom/stream'
# Dictionary:
require_relative 'dicom/d_library'
require_relative 'dicom/dictionary_element'
require_relative 'dicom/uid'
# Image processors:
require_relative 'dicom/image_processor_mini_magick'

module DICOM
  extend DICOM::Configuration

  # Defines the gem root directory in the file system.
  ROOT_DIR = "#{File.dirname(__FILE__)}/dicom"

  # The library instance (data dictionary) of the DICOM module.
  LIBRARY =  DICOM::DLibrary.new

end
