# PDFもサイズ変換しているが、今回そういったことは必要無いので、pdfはサイズ変換しないようにする
module Mars::MagickFileColumn
  def self.included(recipient)
    recipient.class_eval {
      private
      def needs_transform?
        !(File.basename(absolute_path) =~ /\.pdf$/i) and
          options[:magick] and just_uploaded? and
          (options[:magick][:size] or options[:magick][:versions] or options[:magick][:transformation] or options[:magick][:attributes])
      end
    }
  end
end
