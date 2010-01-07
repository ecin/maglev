#include <string.h>

#include <yaml.h>

static void my_handle_event(yaml_event_t *event);


/* TODO: accept an IO object as well? */
static int parse(const unsigned char *input)
{
  yaml_parser_t parser;
  size_t length = strlen(input);

  yaml_parser_initialize(&parser);
  yaml_parser_set_input_string(&parser, input, length);

  int done = 0;
  yaml_event_t event;

  while(!done) {
    if (!yaml_parser_parse(&parser, &event)) {
      fprintf(stderr, "PARSE ERROR\n");
      yaml_parser_delete(&parser);
      return 0;
    }

    my_handle_event(&event);

    done = (event.type == YAML_STREAM_END_EVENT);
    yaml_event_delete(&event);
  }
}

static void my_handle_event(yaml_event_t *event) {
  fprintf(stderr, "handle_event\n");
  switch(event->type) {

  case YAML_STREAM_START_EVENT:
    fprintf(stderr, "YAML_STREAM_START_EVENT\n");
    break;

  case YAML_STREAM_END_EVENT:
    fprintf(stderr, "YAML_STREAM_END_EVENT\n");
    break;



  case YAML_DOCUMENT_START_EVENT:
    fprintf(stderr, "YAML_DOCUMENT_START_EVENT\n");
    break;

  case YAML_DOCUMENT_END_EVENT:
    fprintf(stderr, "YAML_DOCUMENT_END_EVENT\n");
    break;



  case YAML_ALIAS_EVENT:
    fprintf(stderr, "YAML_ALIAS_EVENT\n");
    break;

  case YAML_SCALAR_EVENT:
    fprintf(stderr, "YAML_SCALAR_EVENT\n");
    break;



  case YAML_SEQUENCE_START_EVENT:
    fprintf(stderr, "YAML_SEQUENCE_START_EVENT\n");
    break;

  case YAML_SEQUENCE_END_EVENT:
    fprintf(stderr, "YAML_SEQUENCE_END_EVENT\n");
    break;



  case YAML_MAPPING_START_EVENT:
    fprintf(stderr, "YAML_MAPPING_START_EVENT\n");
    break;

  case YAML_MAPPING_END_EVENT:
    fprintf(stderr, "YAML_MAPPING_END_EVENT\n");
    break;



  case YAML_NO_EVENT:
    fprintf(stderr, "YAML_NO_EVENT\n");
    break;

  default:
    fprintf(stderr, "UNRECOGNIZED EVENT: %d\n", event->type);
    break;
  }
}

int main(int argc, char **argv) {
  const unsigned char *input = "--- a";
  parse(input);
  return 0;
}