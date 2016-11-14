class VersionedAdvertisement < ActiveRecord::Base
  include VersionedResourceStateAndWorkflow

  attr_protected :workflow_id
  
  acts_as_stampable
  acts_as_list :scope => :advertisement_id

  belongs_to :advertisement
  AdvertisementSpecies.fetch( :all ).each do |species|
    has_one species.attachment_class.to_s.underscore.to_sym, :dependent => :destroy
  end
  has_one :swf_backup, :as => :backupable

  def attachment=(attachment)
    self.send( self.species.attachment_class.to_s.underscore + "=", attachment )
  end

  def attachment
    self.send( self.species.attachment_class.to_s.underscore )
  end

  def species
    AdvertisementSpecies.fetch( self.species_id )
  end

  def species=( species_instance )
    case species_instance.class.name
    when "AdvertisementSpecies"
      self.species_id = species_instance.id
    when "Fixnum"
      self.species_id = species_instance
    end
  end

  # This is not db-optimized, but we aren't too concerned about that on the 
  # CMA side for now.
  def deep_clone
    new_versioned_resource = self.clone
    new_versioned_resource.position = nil  # So that acts_as_list gives it the proper position.
    new_versioned_resource.workflow_id = Workflow.fetch( "pending" ).id  # So that doesn't pretend to be published.
    new_versioned_resource.save

    # Attachment.
    unless self.attachment.nil?
      new_versioned_resource.attachment = self.attachment.deep_clone
    end

    unless self.swf_backup.nil?
      new_versioned_resource.swf_backup = self.swf_backup.deep_clone
    end
    
    new_versioned_resource
  end
  
end
