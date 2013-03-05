# encoding: UTF-8

require 'spec_helper'


module DICOM

  describe Anonymizer do

    before :each do
      @anon = TMPDIR + "anon"
      @anon_s = TMPDIR + "anon/"
      @anon_other = TMPDIR + "anon2/"
      @skip = @anon_s + "skip_these"
      @skip_s = @anon_s + "skip_these/"
      @wpath = TMPDIR + "awrite"
      @wpath_s = TMPDIR + "awrite/"
      FileUtils.rmtree(@anon) if File.directory?(@anon)
      FileUtils.rmtree(@anon_other) if File.directory?(@anon_other)
      FileUtils.mkdir_p(@skip)
      FileUtils.mkdir_p(@anon_other)
      FileUtils.copy(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2, @anon)
      FileUtils.copy(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2, @anon_other)
      FileUtils.copy(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2, @skip)
      FileUtils.copy(DCM_EXPLICIT_MR_RLE_MONO2, @anon)
      FileUtils.copy(DCM_EXPLICIT_MR_RLE_MONO2, @anon_other)
      FileUtils.copy(DCM_EXPLICIT_MR_RLE_MONO2, @skip)
      @anon1 = @anon_s + File.basename(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2)
      @anon2 = @anon_s + File.basename(DCM_EXPLICIT_MR_RLE_MONO2)
      @anon3 = @anon_other + File.basename(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2)
      @anon4 = @anon_other + File.basename(DCM_EXPLICIT_MR_RLE_MONO2)
      @skip1 = @skip_s + File.basename(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2)
      @skip2 = @skip_s + File.basename(DCM_EXPLICIT_MR_RLE_MONO2)
      @w1 = @wpath_s + File.basename(DCM_EXPLICIT_MR_JPEG_LOSSY_MONO2)
      @w2 = @wpath_s + File.basename(DCM_EXPLICIT_MR_RLE_MONO2)
      DICOM.logger = Logger.new(STDOUT)
      DICOM.logger.level = Logger::FATAL
      @a = Anonymizer.new
    end


    describe "::new" do

      it "should by default set the audit_trail attribute as nil" do
        @a.audit_trail.should be_nil
      end

      it "should by default set the audit_trail_file attribute as nil" do
        @a.audit_trail_file.should be_nil
      end

      it "should by default set the blank attribute as false" do
        @a.blank.should be_false
      end

      it "should by default set the delete_private attribute as false" do
        @a.delete_private.should be_false
      end

      it "should by default set the encryption attribute as nil" do
        @a.encryption.should be_nil
      end

      it "should by default set the enumeration attribute as false" do
        @a.enumeration.should be_false
      end

      it "should by default set the identity_file attribute as nil" do
        @a.identity_file.should be_nil
      end

      it "should by default set the recursive attribute as nil" do
        @a.recursive.should be_nil
      end

      it "should by default set the uid attribute as nil" do
        @a.uid.should be_nil
      end

      it "should by default set the uid_root attribute as the DICOM module's UID_ROOT constant" do
        @a.uid_root.should eql UID_ROOT
      end

      it "should by default set the write_path attribute as nil" do
        @a.write_path.should be_nil
      end

      it "should pass the :recursive option to the recursive attribute" do
        a = Anonymizer.new(:recursive => true)
        a.recursive.should be_true
      end

      it "should pass the :uid option to the uid attribute" do
        a = Anonymizer.new(:uid => true)
        a.uid.should be_true
      end

      it "should pass the :uid_root option to the uid_root attribute" do
        custom_uid = "1.999.5"
        a = Anonymizer.new(:uid_root => custom_uid)
        a.uid_root.should eql custom_uid
      end

      it "should pass the :audit_trail option to the audit_trail_file attribute" do
        trail_file = 'audit_trail.json'
        a = Anonymizer.new(:audit_trail => trail_file)
        a.audit_trail_file.should eql trail_file
      end

      it "should pass the :encryption option to the encryption attribute when a Digest class is passed (along with the :audit_trail option)" do
        require 'digest'
        a = Anonymizer.new(:audit_trail => 'audit_trail.json', :encryption => Digest::SHA256)
        a.encryption.should eql Digest::SHA256
      end

      it "should set MD5 as the default Digest class when an :encryption option that is not a Digest class is given (along with the :audit_trail option)" do
        a = Anonymizer.new(:audit_trail => 'audit_trail.json', :encryption => true)
        a.encryption.should eql Digest::MD5
      end

      it "should load an AuditTrail instance to the audit_trail attribute when the :audit_trail option is used" do
        a = Anonymizer.new(:audit_trail => 'audit_trail.json')
        a.audit_trail.should be_an AuditTrail
      end

    end


    describe "#add_exception" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.add_exception(42)}.to raise_error(ArgumentError)
      end

      it "should not anonymize files in the exception directory, but still anonymize the other files (with the given paths ending with a separator)" do
        a = Anonymizer.new
        a.add_exception(@skip_s)
        a.add_folder(@anon_s)
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        s1 = DObject.read(@skip1)
        s2 = DObject.read(@skip2)
        a1.value("0010,0010").should eql a.value("0010,0010")
        a2.value("0010,0010").should eql a.value("0010,0010")
        s1.value("0010,0010").should_not eql a.value("0010,0010")
        s2.value("0010,0010").should_not eql a.value("0010,0010")
      end

      it "should not anonymize files in the exception directory, but still anonymize the other files (with the given paths not ending with a separator)" do
        a = Anonymizer.new
        a.add_folder(@anon)
        a.add_exception(@skip)
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        s1 = DObject.read(@skip1)
        s2 = DObject.read(@skip2)
        a1.value("0010,0010").should eql a.value("0010,0010")
        a2.value("0010,0010").should eql a.value("0010,0010")
        s1.value("0010,0010").should_not eql a.value("0010,0010")
        s2.value("0010,0010").should_not eql a.value("0010,0010")
      end

    end


    describe "#add_folder" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.add_folder(42)}.to raise_error(ArgumentError)
      end

      it "should anonymize files in the specified folder as well as any sub-folders (with the given path ending with a separator)" do
        a = Anonymizer.new
        a.add_folder(@anon_s)
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        s1 = DObject.read(@skip1)
        s2 = DObject.read(@skip2)
        a1.value("0010,0010").should eql a.value("0010,0010")
        a2.value("0010,0010").should eql a.value("0010,0010")
        s1.value("0010,0010").should eql a.value("0010,0010")
        s2.value("0010,0010").should eql a.value("0010,0010")
      end

      it "should anonymize files in the specified folder as well as any sub-folders (with the given path ending without a separator)" do
        a = Anonymizer.new
        a.add_folder(@anon)
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        s1 = DObject.read(@skip1)
        s2 = DObject.read(@skip2)
        a1.value("0010,0010").should eql a.value("0010,0010")
        a2.value("0010,0010").should eql a.value("0010,0010")
        s1.value("0010,0010").should eql a.value("0010,0010")
        s2.value("0010,0010").should eql a.value("0010,0010")
      end

      it "should anonymize files in all specified folders, when multiple folders are added" do
        a = Anonymizer.new
        a.add_folder(@anon)
        a.add_folder(@anon_other)
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        a3 = DObject.read(@anon3)
        a4 = DObject.read(@anon4)
        a1.value("0010,0010").should eql a.value("0010,0010")
        a2.value("0010,0010").should eql a.value("0010,0010")
        a3.value("0010,0010").should eql a.value("0010,0010")
        a4.value("0010,0010").should eql a.value("0010,0010")
      end

    end


    describe "#enum" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.value(42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-tag string is passed as an argument" do
        a = Anonymizer.new
        expect {a.value("asdf,asdf")}.to raise_error(ArgumentError)
      end

      it "should return the enumeration boolean for the specified tag" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :enum => true)
        a.enum("0010,0010").should be_true
        a.set_tag("0010,0010", :enum => false)
        a.enum("0010,0010").should be_false
        a.set_tag("0010,0010", :enum => true)
        a.enum("0010,0010").should be_true
      end

    end


    describe "#execute" do

      it "should print information when the logger has been set to a verbose mode" do
        a = Anonymizer.new
        DICOM.logger = Logger.new(LOGDIR + 'anonymizer1.log')
        a.logger.level = Logger::DEBUG
        a.add_folder(@anon_other)
        a.execute
        File.open(LOGDIR + 'anonymizer1.log').readlines.length.should be > 1
      end

      it "should not print information when the logger has been set to a non-verbose mode" do
        a = Anonymizer.new
        DICOM.logger = Logger.new(LOGDIR + 'anonymizer2.log')
        a.logger.level = Logger::UNKNOWN
        a.add_folder(@anon_other)
        a.execute
        File.open(LOGDIR + 'anonymizer2.log').readlines.length.should be <= 1
      end

      it "should anonymize the folder's files according to the list of tags in the anonymization instance" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.execute
        dcm = DObject.read(@anon3)
        dcm.value("0010,0010").should eql a.value("0010,0010")
        dcm.value("0008,0020").should eql a.value("0008,0020")
      end

      it "should not create data elements which are present on the 'list to be anonymized' but not in the target file" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.execute
        dcm = DObject.read(@anon3) # the tag we are testing is not originally present in this file
        a.value("0008,0012").should be_true # make sure the tag we are testing is defined
        dcm.exists?("0008,0012").should be_false
      end

      it "should fill the log with information" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.logger.expects(:info).at_least_once
        a.execute
      end

      it "should use empty strings for anonymization when we have set the blank attribute as true" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.blank = true
        a.execute
        dcm = DObject.read(@anon3)
        dcm.value("0010,0010").should_not eql a.value("0010,0010")
        dcm.value("0010,0010").to_s.length.should eql 0
      end

      it "should use enumerated strings for anonymization when we have set the enumeration attribute as true" do
        a = Anonymizer.new
        a.add_folder(@anon)
        a.enumeration = true
        a.execute
        a1 = DObject.read(@anon1)
        a2 = DObject.read(@anon2)
        s1 = DObject.read(@skip1)
        s2 = DObject.read(@skip2)
        a1.value("0010,0010").should_not eql a.value("0010,0010")
        a1.value("0010,0010").should eql s1.value("0010,0010")
        a2.value("0010,0010").should eql s2.value("0010,0010")
        a1.value("0010,0010").should_not eql a2.value("0010,0010")
        s1.value("0010,0010").should_not eql s2.value("0010,0010")
        a1.value("0010,0010").include?(a.value("0010,0010")).should be_true
        a1.value("0010,0010")[-1..-1].to_i.should_not eql a2.value("0010,0010")[-1..-1].to_i
      end

      it "should not recursively anonymize the tag hierarchies of the DICOM files when the :recursive option is unused" do
        a = Anonymizer.new
        a.add_folder(@anon)
        a.set_tag('0008,0104', :value => 'Recursive')
        a.execute
        dcm = DObject.read(@anon1)
        dcm['0008,2112'][0]['0040,A170'][0].value('0008,0104').should_not eql 'Recursive'
        dcm['0008,9215'][0].value('0008,0104').should_not eql 'Recursive'
      end

      it "should recursively anonymize the tag hierarchies of the DICOM files when the :recursive option is used" do
        a = Anonymizer.new(:recursive => true)
        a.add_folder(@anon)
        a.set_tag('0008,0104', :value => 'Recursive')
        a.execute
        dcm = DObject.read(@anon1)
        dcm['0008,2112'][0]['0040,A170'][0].value('0008,0104').should eql 'Recursive'
        dcm['0008,9215'][0].value('0008,0104').should eql 'Recursive'
      end

      it "should write the anonymized files to the specified folder and leave the original DICOM files untouched, when the write_path attribute is specified (with the path not ending with a file separator)" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.write_path = @wpath
        dcm = DObject.read(@anon3)
        old_value = dcm.value("0010,0010")
        a.execute
        dcm = DObject.read(@anon3)
        after_value = dcm.value("0010,0010")
        after_value.should eql old_value
        w = DObject.read(@w1)
        w.value("0010,0010").should eql a.value("0010,0010")
      end

      it "should write the anonymized files to the specified folder (with the path ending with a separator)" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.write_path = @wpath_s
        a.execute
        w = DObject.read(@w1)
        w.value("0010,0010").should eql a.value("0010,0010")
      end

      # FIXME? There is no specification yet for the format or content of this file printout.
      it "should write the relationship between original and enumerated values to the specified file" do
        a = Anonymizer.new
        a.add_folder(@anon_other)
        a.enumeration = true
        a.identity_file = TMPDIR + "identification.txt"
        a.execute
        File.exists?(TMPDIR + "identification.txt").should be_true
      end

      context " [:uid]" do

        before :each do
          @dcm = DObject.new
          @dcm.add(Element.new('0010,0010', 'John Doe'))
          @dcm.add(Element.new('0002,0010', '1.2.840.10008.1.2.1'))
          @dcm.add(Element.new('0008,0016', '1.2.840.10008.5.1.4.1.1.2'))
          @dcm.add(Element.new('0008,0018', DICOM.generate_uid))
          @dcm.add(Element.new('0020,000D', DICOM.generate_uid))
          @dcm.add(Element.new('0020,000E', DICOM.generate_uid))
          @dcm.add(Element.new('0020,0052', DICOM.generate_uid))
          @rdcm = DObject.new
          @rdcm.add(Element.new('0010,0010', 'John Doe'))
          @rdcm.add(Element.new('0002,0010', '1.2.840.10008.1.2'))
          @rdcm.add(Element.new('0008,0016', '1.2.840.10008.5.1.4.1.1.4'))
          @rdcm.add(Element.new('0008,0018', DICOM.generate_uid))
          @rdcm.add(Element.new('0020,000D', DICOM.generate_uid))
          @rdcm.add(Element.new('0020,000E', DICOM.generate_uid))
          @rdcm.add(Element.new('0020,0052', DICOM.generate_uid))
          @rdcm.add(Sequence.new('0008,1140'))
          @rdcm['0008,1140'].add_item
          @rdcm['0008,1140'][0].add(Element.new('0008,1150', '1.2.840.10008.5.1.4.1.1.2'))
          @rdcm['0008,1140'][0].add(Element.new('0008,1155', DICOM.generate_uid))
          @dir = "#{TMPDIR}/anon/uid_source/"
          @wdir = "#{TMPDIR}/anon/uid_write1/"
          @dcm.write("#{@dir}/source.dcm")
          @rdcm.write("#{@dir}/ref.dcm")
          @path = "#{@wdir}/source.dcm"
          @rpath = "#{@wdir}/ref.dcm"
        end

        it "should by default keep the original UID values" do
          a = Anonymizer.new(:recursive => true)
          a.add_folder(@dir)
          a.write_path = @wdir
          a.execute
          dcm = DObject.read(@path)
          rdcm = DObject.read(@rpath)
          dcm.value('0010,0010').should_not eql @dcm.value('0010,0010')
          dcm.value('0008,0016').should eql @dcm.value('0008,0016')
          dcm.value('0008,0018').should eql @dcm.value('0008,0018')
          rdcm.value('0010,0010').should_not eql @rdcm.value('0010,0010')
          rdcm.value('0008,0016').should eql @rdcm.value('0008,0016')
          rdcm.value('0008,0018').should eql @rdcm.value('0008,0018')
          rdcm['0008,1140'][0].value('0008,1150').should eql @rdcm['0008,1140'][0].value('0008,1150')
          rdcm['0008,1140'][0].value('0008,1155').should eql @rdcm['0008,1140'][0].value('0008,1155')
        end

        it "should not touch the Transfer Syntax UID when the :uid option is used" do
          a = Anonymizer.new(:uid => true)
          a.add_folder(@dir)
          a.write_path = @wdir
          a.execute
          dcm = DObject.read(@path)
          rdcm = DObject.read(@rpath)
          dcm.value('0010,0010').should_not eql @dcm.value('0010,0010')
          rdcm.value('0010,0010').should_not eql @rdcm.value('0010,0010')
          dcm.value('0002,0010').should eql @dcm.value('0002,0010')
          rdcm.value('0002,0010').should eql @rdcm.value('0002,0010')
        end

        it "should not touch the SOP Class UID when the :uid option is used" do
          a = Anonymizer.new(:uid => true)
          a.add_folder(@dir)
          a.write_path = @wdir
          a.execute
          dcm = DObject.read(@path)
          rdcm = DObject.read(@rpath)
          dcm.value('0010,0010').should_not eql @dcm.value('0010,0010')
          rdcm.value('0010,0010').should_not eql @rdcm.value('0010,0010')
          dcm.value('0008,0016').should eql @dcm.value('0008,0016')
          rdcm.value('0008,0016').should eql @rdcm.value('0008,0016')
        end

        it "should replace all relevant UIDs when both the :uid and :recursive options are used" do
          a = Anonymizer.new(:recursive => true, :uid => true)
          a.add_folder(@dir)
          a.write_path = @wdir
          a.execute
          dcm = DObject.read(@path)
          rdcm = DObject.read(@rpath)
          dcm.value('0010,0010').should_not eql @dcm.value('0010,0010')
          rdcm.value('0010,0010').should_not eql @rdcm.value('0010,0010')
          dcm.value('0008,0018').should_not eql @dcm.value('0008,0018')
          dcm.value('0020,000D').should_not eql @dcm.value('0020,000D')
          dcm.value('0020,000E').should_not eql @dcm.value('0020,000E')
          dcm.value('0020,0052').should_not eql @dcm.value('0020,0052')
          rdcm.value('0008,0018').should_not eql @rdcm.value('0008,0018')
          rdcm.value('0020,000D').should_not eql @rdcm.value('0020,000D')
          rdcm.value('0020,000E').should_not eql @rdcm.value('0020,000E')
          rdcm.value('0020,0052').should_not eql @rdcm.value('0020,0052')
          rdcm['0008,1140'][0].value('0008,1155').should_not eql @rdcm['0008,1140'][0].value('0008,1155')
        end

      end

      context " [:audit_trail]" do

        it "should write an audit trail file" do
          audit_file = TMPDIR + "anonymization1.json"
          a = Anonymizer.new(:audit_trail => audit_file)
          a.add_folder(@anon_other)
          a.write_path = @wpath_s
          a.enumeration = true
          a.execute
          File.exists?(audit_file).should be_true
          at = AuditTrail.read(audit_file)
          at.should be_a AuditTrail
        end

        it "should encrypt the values stored in the audit trail file" do
          audit_file = TMPDIR + "anonymization_encrypted.json"
          a = Anonymizer.new(:audit_trail => audit_file, :encryption => true)
          a.add_folder(@anon_other)
          a.write_path = @wpath_s
          a.enumeration = true
          a.execute
          at = AuditTrail.read(audit_file)
          names = at.records('0010,0010').to_a
          # MD5 hashes are 32 characters long:
          names.first[0].length.should eql 32
          names.last[0].length.should eql 32
          # Values should be the ordinary, enumerated ones:
          names.first[1].should eql 'Patient1'
          names.last[1].should eql 'Patient2'
        end

      end

    end


    # FIXME? Currently there is no specification for the format of the element printout (this method is not very important, really).
    #
    describe "#print" do

      it "should print information to the screen" do
        a = Anonymizer.new
        a.expects(:puts).at_least_once
        a.print
      end

    end


    describe "#remove_tag" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.remove_tag(42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-tag string is passed as an argument" do
        a = Anonymizer.new
        expect {a.remove_tag("asdf,asdf")}.to raise_error(ArgumentError)
      end

      it "should remove the tag, with its value and enumeration status, from the list of tags to be anonymized" do
        a = Anonymizer.new
        a.remove_tag("0010,0010")
        a.value("0010,0010").should be_nil
        a.enum("0010,0010").should be_nil
      end

    end

    describe "#delete_tag" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.delete_tag(42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-tag string is passed as an argument" do
        a = Anonymizer.new
        expect {a.delete_tag("asdf,asdf")}.to raise_error(ArgumentError)
      end

      it "should delete tag marked for deletion during anonymization" do
        a = Anonymizer.new
        dcm = DObject.read(@anon3)
        dcm.exists?("0010,0010").should be_true
        a.add_folder(@anon_other)
        a.delete_tag("0010,0010")
        a.execute
        dcm = DObject.read(@anon3)
        dcm.exists?("0010,0010").should be_false
      end

    end


    describe "#set_tag" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.set_tag(42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-tag string is passed as an argument" do
        a = Anonymizer.new
        expect {a.set_tag("asdf,asdf")}.to raise_error(ArgumentError)
      end

      it "should add the tag, with its value, to the list of tags to be anonymized" do
        a = Anonymizer.new
        a.set_tag("0040,2008", :value => "none")
        a.value("0040,2008").should eql "none"
      end

      it "should add the tag, using the default empty string as value, when no value is specified for this string type element" do
        a = Anonymizer.new
        a.set_tag("0040,2008")
        a.value("0040,2008").should eql ""
      end

      it "should add the tag, using 0 as the default value for this integer type element" do
        a = Anonymizer.new
        a.set_tag("0010,21C0")
        a.value("0010,21C0").should eql 0
      end

      it "should add the tag, using 0.0 as the default value for this float type element" do
        a = Anonymizer.new
        a.set_tag("0010,9431")
        a.value("0010,9431").should eql 0.0
      end

      it "should update the tag, with the new value, when a pre-existing tag is specified" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :value => "KingAnonymous")
        a.value("0010,0010").should eql "KingAnonymous"
      end

      it "should update the tag, keeping the old value, when a pre-existing tag is specified but no value given" do
        a = Anonymizer.new
        old_value = a.value("0010,0010")
        a.set_tag("0010,0010")
        a.value("0010,0010").should eql old_value
      end

      it "should update the enumeration status of the pre-listed tag, when specified" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :enum => true)
        a.enum("0010,0010").should be_true
      end

      it "should set the enumeration status for the newly created tag entry, when specified" do
        a = Anonymizer.new
        a.set_tag("0040,2008", :enum => true)
        a.enum("0040,2008").should be_true
      end

      it "should not change the enumeration status of a tag who's old value is true, when enumeration is not specified" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :enum => true)
        a.set_tag("0010,0010")
        a.enum("0010,0010").should be_true
      end

      it "should not change the enumeration status of a tag who's old value is false, when enumeration is not specified" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :enum => false)
        a.set_tag("0010,0010")
        a.enum("0010,0010").should be_false
      end

      it "should set the enumeration status for the newly created tag entry as false, when enumeration not specified" do
        a = Anonymizer.new
        a.set_tag("0040,2008")
        a.enum("0040,2008").should be_false
      end

    end


    describe "#value" do

      it "should raise an ArgumentError when a non-string is passed as an argument" do
        a = Anonymizer.new
        expect {a.value(42)}.to raise_error(ArgumentError)
      end

      it "should raise an ArgumentError when a non-tag string is passed as an argument" do
        a = Anonymizer.new
        expect {a.value("asdf,asdf")}.to raise_error(ArgumentError)
      end

      it "should return the anonymization value to be used for the specified tag" do
        a = Anonymizer.new
        a.set_tag("0010,0010", :value => "custom_value")
        a.value("0010,0010").should eql "custom_value"
      end

    end

  end

end
