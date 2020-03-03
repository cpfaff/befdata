//= require datatables/jquery.dataTables

// optional change '//' --> '//=' to enable

// require datatables/extensions/AutoFill/dataTables.autoFill
// require datatables/extensions/Buttons/dataTables.buttons
// require datatables/extensions/Buttons/buttons.html5
// require datatables/extensions/Buttons/buttons.print
// require datatables/extensions/Buttons/buttons.colVis
// require datatables/extensions/Buttons/buttons.flash
// require datatables/extensions/ColReorder/dataTables.colReorder
// require datatables/extensions/FixedColumns/dataTables.fixedColumns
// require datatables/extensions/FixedHeader/dataTables.fixedHeader
// require datatables/extensions/KeyTable/dataTables.keyTable
//= require datatables/extensions/Responsive/dataTables.responsive
// require datatables/extensions/RowGroup/dataTables.rowGroup
// require datatables/extensions/RowReorder/dataTables.rowReorder
// require datatables/extensions/Scroller/dataTables.scroller
// require datatables/extensions/Select/dataTables.select

//= require datatables/dataTables.bootstrap4
// require datatables/extensions/AutoFill/autoFill.bootstrap4
// require datatables/extensions/Buttons/buttons.bootstrap4
//= require datatables/extensions/Responsive/responsive.bootstrap4


//Global setting and initializer

$.extend( $.fn.dataTable.defaults, {
  responsive: true,
  pagingType: 'full',
  pagingType: 'full_numbers',
  dom: '<"float-left"f><"float-right"l>rt<"float-left pl-1"i><"float-right"p>',
  language: {
    search: "Filter:"
  },
  search: {
    regex: true
  }
  //dom:
  //  "<'row'<'col-sm-4 text-left'f><'right-action col-sm-8 text-right'<'buttons'B> <'select-info'> >>" +
  //  "<'row'<'dttb col-12 px-0'tr>>" +
  //  "<'row'<'col-sm-12 table-footer'lip>>"
});


$(document).on('preInit.dt', function(e, settings) {
  var api, table_id, url;
  api = new $.fn.dataTable.Api(settings);
  table_id = "#" + api.table().node().id;
  url = $(table_id).data('source');
  if (url) {
    return api.ajax.url(url);
  }
});


// init on turbolinks load
$(document).on('turbolinks:load', function() {
  if (!$.fn.DataTable.isDataTable("table[id^=dttb-]")) {
    $("table[id^=dttb-]").DataTable();
  }
});

// turbolinks cache fix
$(document).on('turbolinks:before-cache', function() {
  var dataTable = $($.fn.dataTable.tables(true)).DataTable();
  if (dataTable !== null) {
    dataTable.clear();
    dataTable.destroy();
    return dataTable = null;
  }
});

// example table
// %table#index_projects.table.table-striped{ width: "100%"}
  // %thead
    // %tr
      // %th Shortname
      // %th Project
  // %tbody
    // - @projects.each do |project|
      // %tr
        // %td
          // = project.shortname
        // %td
          // %div.pb-2
            // = link_to project.name, project_path(project)
          // - unless project.description.blank?
            // %div.pb-2
              // .text-justify
                // Description:
                // = project.description.truncate(180)
          // - unless project.comment.blank?
            // %div
              // .text-justify
                // = show_to :admin, :data_admin, :project_board do
                  // .text-muted
                    // Note:
                    // = project.comment


// example initialization
// :javascript
  // $(document).ready(function() {
    // $('#index_datasets').DataTable( {
      // pagingType: "full_numbers",
      // dom: '<"float-left"f><"float-right"l>rt<"float-left pl-1"i><"float-right"p>',
      // language: {
        // search: "Filter:"
        // },
      // search: {
        // regex: true
      // },
      // columnDefs: [
          // { className: 'text-left', targets: [0, 3] },
          // { className: 'text-center', targets: [1, 2] }
        // ]
    // } );
  // } );
//


