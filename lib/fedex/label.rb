require 'base64'
require 'pathname'

module Fedex
  class Label
    attr_accessor :options, :image, :response_details

    # Initialize Fedex::Label Object
    # @param [Hash] options
    def initialize(label_details = {})
      @response_details = label_details[:process_shipment_reply]
      package_details = label_details[:process_shipment_reply][:completed_shipment_detail][:completed_package_details]
      @options = package_details[:label]
      @options[:tracking_number] = package_details[:tracking_ids][:tracking_number]
      @options[:format] = label_details[:format]
      @options[:file_name] = label_details[:file_name]
      operational_details = package_details[:operational_detail][:operational_instructions]
      if operational_details.present?
        @options[:form_id] = operational_details[1][:content]
        @options[:routing_code] = operational_details[2][:content]
        @options[:time_of_delivery] = operational_details[6][:content]
        @options[:service_type] = operational_details[7][:content]
        if @options[:form_id] == "0305"
          @options[:shipment_type] = operational_details[8][:content]
          @options[:airport_id] = operational_details[11][:content]
        elsif @options[:form_id] == "0467"
          @options[:shipment_type] = "PREPAID"
          @options[:airport_id] = operational_details[10][:content]
        else
          @options[:shipment_type] = ""
          @options[:airport_id] = ""
        end
      end
      barcode = label_details[:process_shipment_reply][:completed_shipment_detail][:completed_package_details][:operational_detail][:barcodes]
      @options[:barcode_type] = barcode[:string_barcodes][:type]
      @options[:barcode_content] = barcode[:string_barcodes][:value]

      cod_return_detail = label_details[:process_shipment_reply][:completed_shipment_detail][:associated_shipments]
      if cod_return_detail.present?
        @options[:cod_return_tracking_number] = cod_return_detail[:tracking_id][:tracking_number]
        cod_barcode = label_details[:process_shipment_reply][:completed_shipment_detail][:associated_shipments][:package_operational_detail][:barcodes]
        @options[:cod_barcode_type] = cod_barcode[:string_barcodes][:type]
        @options[:cod_barcode_content] = cod_barcode[:string_barcodes][:value]        
        @options[:cod_tracking_number] = cod_return_detail[:tracking_id][:tracking_number]
        package_operational_details = cod_return_detail[:package_operational_detail][:operational_instructions]
        @options[:cod_form_id] = package_operational_details[1][:content]
        @options[:cod_service_type] = package_operational_details[5][:content]
        @options[:cod_shipment_type] = package_operational_details[6][:content]
      end
      
      @image = Base64.decode64(options[:parts][:image]) if has_image?

      if file_name = @options[:file_name]
        save(file_name, false)
      end
    end

    def name
      [tracking_number, format].join('.')
    end

    def format
      options[:format]
    end

    def file_name
      options[:file_name]
    end

    def tracking_number
      options[:tracking_number]
    end

    def cod_return_tracking_number
      options[:cod_return_tracking_number]
    end

    def form_id
      options[:form_id]
    end

    def cod_form_id
      options[:cod_form_id]
    end
     
    def routing_code
      options[:routing_code]
    end
        
    def shipment_type
      options[:shipment_type]
    end
        
    def cod_shipment_type
      options[:cod_shipment_type]
    end
        
    def service_type
      options[:service_type]
    end
        
    def cod_service_type
      options[:cod_service_type]
    end 
        
    def time_of_delivery
      options[:time_of_delivery]
    end

    def airport_id
      options[:airport_id]
    end

    def barcode_type
      options[:barcode_type]
    end

    def cod_barcode_type
      options[:cod_barcode_type]
    end

    def barcode_content
      options[:barcode_content]
    end

    def cod_barcode_content
      options[:cod_barcode_content]
    end

    def has_image?
      options[:parts] && options[:parts][:image]
    end

    def save(path, append_name = true)
      return unless has_image?

      full_path = Pathname.new(path)
      full_path = full_path.join(name) if append_name

      File.open(full_path, 'wb') do|f|
        f.write(@image)
      end
    end
  end
end


#for prepared forward
#0 [{:number=>"2", :content=>"TRK#"},  
#1  {:number=>"3", :content=>"0305"}, # FormId
#2  {:number=>"5", :content=>"00 IXUA "}, #Routing Code
#3  {:number=>"7", :content=>"1021448682541055303700794608259420"},
#4  {:number=>"8", :content=>"522G1/62D3/F220"},
#5  {:number=>"10", :content=>"7946 0825 9420"}, #tracking number(we take tracking code from tracking_id)
#6  {:number=>"12", :content=>"AA"}, #Time of delivery
#7  {:number=>"13", :content=>"STANDARD OVERNIGHT"}, #Service Type
#8  {:number=>"14", :content=>"COD"}, #shipment type
#9  {:number=>"15", :content=>"431001"},
#10 {:number=>"16", :content=>"  -IN"},
#11 {:number=>"17", :content=>"DEL"}] #Airport id

#for cod forward
#0 [{:number=>"2", :content=>"TRK#"},
#1  {:number=>"3", :content=>"0305"}, # COD FormId
#2  {:number=>"5", :content=>"00 BOMNP"},
#3  {:number=>"7", :content=>"1021448682691052205600794608281764"},
#4  {:number=>"8", :content=>"522G1/62D3/F220"},
#5  {:number=>"10", :content=>"7946 0828 1764"}, # COD tracking number(we take tracking code from tracking_id)
#6  {:number=>"12", :content=>"AA"},
#7  {:number=>"13", :content=>"STANDARD OVERNIGHT"}, #Service Type
#8  {:number=>"14", :content=>"COD"}, #COD shipment type
#9  {:number=>"15", :content=>"400020"},
#10 {:number=>"16", :content=>"  -IN"},
#11 {:number=>"17", :content=>"BOM"}]


#for cod return
#0 [{:number=>"2", :content=>"TRK#"},
#1  {:number=>"3", :content=>"0325"},
#2  {:number=>"7", :content=>"1021467002691052205600794608281775"},
#3  {:number=>"8", :content=>"522G1/62D3/F220"},
#4  {:number=>"10", :content=>"7946 0828 1775"},
#5  {:number=>"13", :content=>"PRIORITY OVERNIGHT"},
#6  {:number=>"14", :content=>"COD RETURN"},
#7  {:number=>"15", :content=>"400020"},
#8  {:number=>"16", :content=>"  -IN"},
#9  {:number=>"19", :content=>"COD AMOUNT 699.00 INR"},
#10 {:number=>"20", :content=>"UNSECURED"}]
