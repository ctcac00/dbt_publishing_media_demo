{% macro pence_to_pounds(column_name, scale=2) %}
    round({{ column_name }} / 100, {{ scale }})
{% endmacro %}
