// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function selectPeople(select) {
	if (select.options[select.selectedIndex].value == "") {
		// The prompt option has no value and thus can't be added. 
		return;
	}
    var option = select.options[select.selectedIndex];
    var ul = document.getElementById('people-list');
    var choices = ul.getElementsByTagName('input');
    for (var i = 0; i < choices.length; i++) if (choices[i].value == option.value) return;
    var image = document.createElement('img');
    image.setAttribute('src', '/images/cancel.png');
    var li = document.createElement('li');
    var input = document.createElement('input');
    var text = document.createTextNode(option.firstChild.data);
    input.type = 'hidden';
    input.name = 'people[]';
    input.value = option.value;
    li.appendChild(input);
    li.appendChild(image);
    li.appendChild(text);
    li.setAttribute('onclick', 'this.parentNode.removeChild(this);');
    ul.appendChild(li);
}

function selectProjects(select) {
	if (select.options[select.selectedIndex].value == "") {
		// The prompt option has no value and thus can't be added.
		return;
	}
    var option = select.options[select.selectedIndex];
    var ul = document.getElementById('projects-list');
    var choices = ul.getElementsByTagName('input');
    for (var i = 0; i < choices.length; i++) if (choices[i].value == option.value) return;
    var image = document.createElement('img');
    image.setAttribute('src', '/images/cancel.png');
    var li = document.createElement('li');
    var input = document.createElement('input');
    var text = document.createTextNode(option.firstChild.data);
    input.type = 'hidden';
    input.name = 'dataset[project_ids][]';
    input.value = option.value;
    li.appendChild(input);
    li.appendChild(image);
    li.appendChild(text);
    li.setAttribute('onclick', 'this.parentNode.removeChild(this);');
    ul.appendChild(li);
}

function selectDatasets(select) {
    if (select.options[select.selectedIndex].value == "") {
        // The prompt option has no value and thus can't be added.
        return;
    }
    var option = select.options[select.selectedIndex];
    var table_body = document.getElementById('collect-datasets-tbody');

    var id = option.value;
    var choices = table_body.getElementsByTagName('input');
    for (var i = 0; i < choices.length; i++) if (choices[i].value == id) return;

    var tr = document.createElement('tr');
    var td_text = document.createElement('td');
    var td_select = document.createElement('td');
    var td_remove = document.createElement('td');

    var input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'paperproposal[dataset_ids][]';
    input.value = option.value;

    var text = document.createTextNode(option.firstChild.data);
    td_text.appendChild(text);

    var aspect_select = document.createElement('select');
    aspect_select.id = "aspect_" + id
    aspect_select.name = "aspect[" + id + "]";
    var option_1 = document.createElement('option');
    option_1.value = 'main';
    var option_1_text = document.createTextNode('main');
    option_1.appendChild(option_1_text);
    aspect_select.appendChild(option_1);
    var option_2 = document.createElement('option');
    option_2.value = 'side';
    var option_2_text = document.createTextNode('side');
    option_2.appendChild(option_2_text);
    aspect_select.appendChild(option_2);
    td_select.appendChild(aspect_select);

    var a = document.createElement('a');
    a.text = 'Remove';
    a.setAttribute('onclick', 'this.parentNode.parentNode.parentNode.removeChild(this.parentNode.parentNode);');
    td_remove.appendChild(a);

    tr.appendChild(input);
    tr.appendChild(td_text);
    tr.appendChild(td_select);
    tr.appendChild(td_remove);

    table_body.appendChild(tr);
}

function clone_element_before(element) {
    var input = element.previousSibling.previousSibling;
    alert(input);
    var name = input.name;
    var id= input.id;
    name = name.replace(/\[([0-9])\]*/, function(variable, p1) {
        var zahl = parseInt(p1)
        zahl = zahl +1
      return "[" + zahl + "]";
        });
    id = id.replace(/_([0-9])*_/, function(variable, p1) {
        var zahl = parseInt(p1)
        zahl = zahl +1
      return "_" + zahl + "_";
        });
    var new_input = document.createElement('input')
    new_input.name = name;
    new_input.type = input.type
    new_input.id = id;
    new_input.size = 30;
    element.append(new_input);
}

function clone_me() {
    this.clone().appendTo(this.parent);
}
