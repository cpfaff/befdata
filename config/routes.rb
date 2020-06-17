# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root to: 'pages#home'

  resource :user_session, only: [:create]
  match 'logout' => 'user_sessions#destroy', :as => :logout, via: %i[get post]

  resources :users
  # TODO: check which profile resources still need to be there remove the
  # rest including its views
  resource :profile, only: %i[show edit update] do
    member do
      get :votes
      post :update_credentials
      resources :notifications, only: %i[index destroy] do
        get :mark_as_read, on: :member
      end
    end
  end

  match 'legal' => 'pages#legal', :as => :legal, via: %i[get post]
  get 'help' => redirect('https://github.com/befdata/befdata/wiki'), :as => :help

  # resources :datasets, :except => [:index] do
  resources :datasets do
    post :create_with_datafile, on: :collection
    resources :datafiles, only: [:destroy] do
      get :download, on: :member
    end
    resources :dataset_edits, only: [:index] do
      post :submit, on: :member
    end
    member do
      post :update_workbook, :approve_predefined, :batch_update_columns
      get :download, :edit_files, :importing, :approve, :approval_quick,
          :keywords, :download_status, :freeformats_csv
    end
  end

  scope path: '/files' do
    resources :freeformats, only: %i[create edit update destroy] do
      get :download, on: :member
    end
  end

  resources :keywords, controller: 'tags', only: %i[index] do
    collection do
      get :manage
      post :delete, :pre_rename, :pre_merge, :rename, :merge
    end
  end

  resources :projects

  resources :datacolumns do
    member do
      get :approval_overview, :next_approval_step,
          :approve_datagroup, :approve_datatype, :approve_metadata, :approve_invalid_values, :annotate
      post :update_datagroup, :create_and_update_datagroup, :update_datatype, :update_metadata, :update_invalid_values,
           :update_invalid_values_with_csv, :autofill_and_update_invalid_values, :update_annotation
    end
  end

  resources :paperproposals do
    member do
      get :edit_datasets, :edit_files, :administrate_votes, :admin_approve_all_votes, :admin_reset_all_votes, :admin_hard_reset
      post :update_datasets
      delete :safe_delete
    end
  end
  match 'paperproposals/update_vote/:id' => 'paperproposals#update_vote', :as => :update_vote, via: %i[get post patch]
  match 'paperproposals/update_state/:id' => 'paperproposals#update_state', :as => :paperproposal_update_state, via: %i[get post patch]

  match 'create_cart_context/:dataset_id' => 'carts#create_cart_context', :as => :create_cart_context, via: %i[get post]
  match 'delete_cart_context/:dataset_id' => 'carts#delete_cart_context', :as => :delete_cart_context, via: %i[get post patch delete]
  match 'cart' => 'carts#show', :as => 'current_cart', via: %i[get post]

  resources :datagroups do
    resources :categories, only: %i[index create new]
    member do
      # TODO: check if this can be removed
      # get :upload_categories
      get :datacolumns
      post :update_categories, :import_categories
    end
  end

  resources :categories, only: %i[show destroy] do
    member do
      get :upload_sheetcells
      post :update_sheetcells
    end
  end

  resources :exported_files, only: [] do
    get :regenerate_download, on: :member
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
