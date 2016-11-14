class Admin::AdvertisementsController < Admin::ApplicationController

  before_filter :find_advertisement, :only => [ :show, :update, :destroy ]

  # GET /advertisements
  def index
    params[:filter_species] ||= AdvertisementSpecies.fetch( :first ).id if params[:search].blank?
      
    @advertisements = search(  { :model => Advertisement } )

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /advertisements/1
  def show
    respond_to do |format|
      format.html { render :action => 'form' }
    end
  end

  # GET /advertisements/new
  def new
    @advertisement = VersionedAdvertisement.new( :species_id => params[:species_id] )

    respond_to do |format|
      format.html { render :action => 'form' }
    end
  end

  # POST /advertisements
  def create
    @advertisement = Advertisement.new( params[:advertisement] )
    @versioned_advertisement = consider_workflow_for VersionedAdvertisement.new( params[:versioned_advertisement] )

    respond_to do |format|
      if @advertisement.save && @versioned_advertisement.save && ( @advertisement.versioned_advertisements << @versioned_advertisement )
        consider_attachment @versioned_advertisement, @versioned_advertisement.species.attachment_class.to_s.underscore.to_sym
        consider_attachment @versioned_advertisement, :swf_backup
        stamp @versioned_advertisement
        flash[:notice] = 'Advertisement was successfully created.'
        format.html { redirect_to( admin_advertisements_url( :filter_species => @versioned_advertisement.species_id ) ) }
      else
        format.html { render :action => 'form' }
      end
    end
  end

  # PUT /advertisements/1
  def update
    @advertisement = consider_workflow_for @advertisement
  
    respond_to do |format|
      if @advertisement.workflow.is_destroyed?
        format.html { redirect_to( admin_advertisements_url( :filter_species => @advertisement.species_id ) ) }
      elsif @advertisement.update_attributes( params[:versioned_advertisement] )
        
        if params[:delete_image]=='yes'
          case @advertisement.species_id
            when 1
              @advertisement.advertisement_curtain = nil
            when 2
              @advertisement.advertisement_leaderboard = nil
            when 3
              @advertisement.advertisement_square = nil
            when 4
              @advertisement.advertisement_sponsored_item = nil            
            when 5
              @advertisement.advertisement_tower = nil              
          end
          @advertisement.save
        end
        consider_attachment @advertisement, @advertisement.species.attachment_class.to_s.underscore.to_sym
        consider_attachment @advertisement, :swf_backup
        
        stamp @advertisement
        flash[:notice] = 'Advertisement was successfully updated.'
        format.html { redirect_to( admin_advertisements_url( :filter_species => @advertisement.species_id ) ) }
      else
        format.html { render :action => 'form' }
      end
    end
  end

  # DELETE /advertisements/1
  def destroy
    destroy_considering_workflow @advertisement

    respond_to do |format|
      format.js
    end
  end

  protected
    def find_advertisement
      @advertisement = Advertisement.find( params[:id] ).most_recent
    end

end
