{% macro calculate_threshold(mean, std_dev, multiplier) %}
{{ mean }} - ({{ multiplier }} * {{ std_dev }})
{% endmacro %}
