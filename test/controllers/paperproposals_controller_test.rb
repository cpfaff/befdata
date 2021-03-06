# frozen_string_literal: true

require 'test_helper'

class PaperproposalsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test 'should get index' do
    get :index
    assert_success_no_error
  end

  test 'should get index as csv' do
    login_nadrowski
    get :index, params: { format: :csv }
    assert_success_no_error
  end

  test 'without login should not be able to edit' do
    @request.env['HTTP_REFERER'] = root_url
    get :edit, params: { id: Paperproposal.first.id }
    assert_match /.*Access denied.*/, flash[:error]
  end

  test 'admin can administrate votes' do
    login_nadrowski
    get :administrate_votes, params: { id: 5 }
    assert_success_no_error
  end

  test 'admin can reset all votes' do
    @request.env['HTTP_REFERER'] = root_url
    paperproposal = Paperproposal.find 5
    login_nadrowski
    get :update_vote, params: { id: paperproposal.paperproposal_votes.first.id, paperproposal_vote: { vote: 'accept' } } # vote something
    assert_equal 1, paperproposal.paperproposal_votes.reload.select { |v| v.vote == 'none' }.count
    get :admin_reset_all_votes, params: { id: paperproposal.id }
    assert_equal 2, paperproposal.paperproposal_votes.reload.select { |v| v.vote == 'none' }.count
  end

  test 'admin can approve all votes' do
    paperproposal = Paperproposal.find 5
    login_nadrowski
    get :admin_approve_all_votes, params: { id: paperproposal.id }
    assert_success_no_error
    paperproposal.reload
    paperproposal.board_state = 'accept'
  end

  test 'admin can completely reset proposal' do
    paperproposal = Paperproposal.find 4
    old_votes_count = PaperproposalVote.all.count
    old_roles_count = User.find(paperproposal.author.id).roles.count
    login_nadrowski

    # make paperproposal final
    get :update_state, params: { id: paperproposal.id, paperproposal: { board_state: 'submit' } }
    get :admin_approve_all_votes, params: { id: paperproposal.id }
    get :admin_approve_all_votes, params: { id: paperproposal.id }
    assert_not_equal User.find(paperproposal.author.id).roles.count, old_roles_count

    # and now reset
    get :admin_hard_reset, params: { id: paperproposal.id }

    assert_equal old_votes_count, PaperproposalVote.all.count
    assert_equal old_roles_count, User.find(paperproposal.author.id).roles.count
    assert_equal 'prep', paperproposal.board_state
    assert_not_nil Paperproposal.find(paperproposal.id)
  end

  test 'automatic vote for author and free dataset owners' do
    paperproposal = Paperproposal.find 6
    login_nadrowski
    old_notification_count = Notification.count

    post :update_state, params: { id: paperproposal.id, paperproposal: { board_state: 'submit' } }

    paperproposal.reload
    assert_equal 1, paperproposal.project_board_votes.where("vote = 'accept'").count

    get :admin_approve_all_votes, params: { id: paperproposal.id }

    paperproposal.reload
    assert_equal paperproposal.board_state, 'final'
    assert Notification.count == (old_notification_count + 1)
  end

  test 'rejecting paperproposal data request' do
    @request.env['HTTP_REFERER'] = root_url
    paperproposal = Paperproposal.find 5
    user = login_nadrowski
    old_notifications_count = Notification.count

    get :admin_approve_all_votes, params: { id: paperproposal.id } # bring to next stage

    get :update_vote, params: { id: user.paperproposal_votes.where(vote: 'none').first.id, paperproposal_vote: { vote: 'reject' } }

    paperproposal.reload
    assert_equal 'data_rejected', paperproposal.board_state
    assert Notification.count > old_notifications_count
  end

  test 'changing datasets recalculates votes and resets if neccesary' do
    @request.env['HTTP_REFERER'] = root_url
    paperproposal = Paperproposal.find 5
    user = login_nadrowski
    get :admin_approve_all_votes, params: { id: paperproposal.id } # bring to next stage
    vote = user.paperproposal_votes.where(vote: 'none').first

    get :update_vote, params: { id: vote.id, paperproposal_vote: { vote: 'accept' } }
    post :update_datasets, params: { id: paperproposal.id, datasets: [{ id: 6, aspect: 'main' }, { id: 7, aspect: 'main' }, { id: 8, aspect: 'side' }] }

    voters = paperproposal.for_data_request_votes.reload.collect(&:user_id).sort
    vote.reload

    assert_equal [1, 3, 5], voters
    assert_equal 'none', vote.vote
  end

  test 'should get new' do
    login_nadrowski
    get :new
    assert_success_no_error
  end

  test 'create new paperproposal' do
    login_nadrowski

    post :create, params: { paperproposal: { title: 'Test', rationale: 'Rational', author_id: 1 } }
    assert_success_no_error
    paperproposal = Paperproposal.find_by_title('Test')

    assert_redirected_to edit_datasets_paperproposal_path(paperproposal)
  end

  test 'should have initial title same as the title after creation process' do
    login_nadrowski

    post :create, params: { paperproposal: { title: 'Test', rationale: 'Rational', author_id: 1 } }
    assert_success_no_error
    paperproposal = Paperproposal.find_by_title('Test')

    assert paperproposal.initial_title == 'Test'
  end

  test 'show paperproposal' do
    login_nadrowski
    get :show, params: { id: 1 }
    assert_success_no_error
  end

  test 'show metadata edit' do
    login_nadrowski
    get :edit, params: { id: 1 }
    assert_success_no_error
  end

  test 'show manage datasets' do
    login_nadrowski
    get :edit_datasets, params: { id: 1 }
    assert_success_no_error
  end

  test 'show manage freeformat files' do
    login_nadrowski
    get :edit_files, params: { id: 1 }
    assert_success_no_error
  end

  test 'updating also refreshes author list' do
    login_nadrowski
    paperproposal = Paperproposal.find 1
    old_authors_count = paperproposal.all_authors_ordered.count
    post :update, params: { id: paperproposal.id, paperproposal: { envisaged_journal: 'testjournal' }, people: [5, 3, 4] }
    paperproposal.reload
    assert old_authors_count > paperproposal.all_authors_ordered.count
  end

  test 'vote on paperproposal is reflected in ui' do
    @request.env['HTTP_REFERER'] = root_url
    login_nadrowski
    paperproposal = Paperproposal.find 5
    vote = PaperproposalVote.find 1
    get :update_vote, params: { id: vote.id, paperproposal_vote: { vote: 'accept' } }
    get :show, params: { id: paperproposal.id }
    assert_success_no_error
    assert_select 'img[alt="Arrow right accept"]'
  end

  test 'should be able to remove all datasets' do
    login_and_load_paperproposal 'nadrowski', 'Step 3 Paperproposal'
    dataset_count_before = @paperproposal.datasets.count
    assert dataset_count_before > 0
    post :update_datasets, params: { id: @paperproposal.id }
    @paperproposal.reload
    dataset_count_after = @paperproposal.datasets.count
    assert_equal dataset_count_after, 0
  end

  test 'should add datasets to paperproposal and the author list is changed' do
    login_and_load_paperproposal 'nadrowski', 'Step 1 Paperproposal'
    @dataset_with_michael = Dataset.find_by_title('Test species name import second version')
    old_authors_count = @paperproposal.all_authors_ordered.count

    get :edit_datasets, params: { id: @paperproposal.id }
    assert_select 'tbody tr', count: 0

    post :update_datasets, params: { id: @paperproposal.id, datasets: [{ id: @dataset_with_michael.id, aspect: 'main' }] }
    assert_redirected_to paperproposal_path(@paperproposal)

    @paperproposal.reload
    assert_equal 1, @paperproposal.datasets.count
    assert old_authors_count < @paperproposal.all_authors_ordered.count

    get :show, params: { id: @paperproposal.id }
    assert_select 'span.comma-separated-list', /.*Michael.*/, response.body
  end

  test 'should not send to board if no dataset is set' do
    login_and_load_paperproposal 'nadrowski', 'Step 1 Paperproposal'

    get :edit, params: { id: @paperproposal.id }
    assert_success_no_error

    assert_select 'form#update_state_edit', false, 'Without any dataset you can not send to board'
  end

  test 'should send to board if it is possible' do
    login_and_load_paperproposal 'pinutrientcycling', 'Step 2 Paperproposal'

    post :update_state, params: { id: @paperproposal.id, paperproposal: { board_state: 'submit' } }
    @paperproposal.reload

    assert (@paperproposal.board_state == 'submit')
    assert_redirected_to @paperproposal
  end

  test 'should show [Submitted to board, waiting for acceptance.] after send to project board' do
    login_and_load_paperproposal 'pinutrientcycling', 'Step 2 Paperproposal'

    post :update_state, params: { id: @paperproposal.id, paperproposal: { board_state: 'submit' } }

    get :show, params: { id: @paperproposal.id }

    assert_success_no_error
    assert_select 'div', text: /submitted to board, waiting for acceptance/
  end

  test 'for project board member it should be possible to vote' do
    skip 'Untestable because vote is in view of user controller and action in paperproposal'
  end

  test 'project board can reject the paperproposal' do
    skip 'Untestable because vote is in view of user controller and action in paperproposal'
  end

  test 'it should be possible to edit a rejected paperproposal' do
    login_and_load_paperproposal 'nadrowski', 'Step 3 Paperproposal rejected'

    get :edit, params: { id: @paperproposal.id }

    assert_success_no_error
  end

  test 'it should not be possible to edit a paperproposal in vote' do
    login_and_load_paperproposal 'Piproductivity', 'Step 3 Paperproposal'

    get :edit, params: { id: @paperproposal.id }

    assert_response :redirect
  end

  test 'should show a paperproposal for owner' do
    skip 'paperproposal is show for everybody.'
  end

  test 'should show a paperproposal for project board if they can vote for it' do
    skip 'paperproposal is show for everybody.'
  end

  test 'should show a paperproposal for dataset owner and responsible if they can vote' do
    skip 'paperproposal is show for everybody.'
  end

  test 'should not show the initial title on create page' do
    login_nadrowski

    get :new

    assert_select 'div#content' do |element|
      assert element.first !~ /Initial title/
    end
  end

  test 'should allow download of datasets to paperproposers if final' do
    skip 'functionality not jet implemented'
  end

  test 'should download paperproposal datasets csv' do
    login_and_load_paperproposal 'Phdstudentnutrientcycling', 'Nutrient cycling and diversity in subtropical forests'

    get :show, params: { id: @paperproposal.id, format: :csv }

    assert_success_no_error
  end

  test 'user can delete fresh paperproposal' do
    login_and_load_paperproposal 'Phdstudentnutrientcycling', 'Nutrient cycling and diversity in subtropical forests'
    old_pp_count = Paperproposal.all.count

    get :safe_delete, params: { id: @paperproposal.id }

    assert_equal Paperproposal.all.count + 1, old_pp_count
  end

  test 'user can only flag for deletion after sumbission' do
    login_and_load_paperproposal 'Phdstudentnutrientcycling', 'Nutrient cycling and diversity in subtropical forests'
    old_pp_count = Paperproposal.all.count

    get :update_state, params: { id: @paperproposal.id }
    @paperproposal.reload
    assert @paperproposal.lock

    get :safe_delete, params: { id: @paperproposal.id }

    assert_equal Paperproposal.all.count, old_pp_count
    @paperproposal.reload
    assert_equal 'deletion', @paperproposal.state
  end

  test 'destroying datasets also deletes dependent objects' do
    models = %w[Role DatasetPaperproposal Paperproposal PaperproposalVote AuthorPaperproposal]
    before = {}
    models.each do |model|
      before[model] = eval("#{model}.count")
    end
    login_and_load_paperproposal 'nadrowski', 'Final Paperproposal'

    get :safe_delete, params: { id: @paperproposal.id }

    after = {}
    models.each do |model|
      after[model] = eval("#{model}.count")
    end

    before.each do |model, before_count|
      assert before_count > after[model], "For #{model} the numbers are: #{before_count} -> #{after[model]}"
    end
  end
end
