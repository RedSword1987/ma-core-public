/**
 * Copyright (C) 2015 Infinite Automation Software. All rights reserved.
 * @author Terry Packer
 */
package com.serotonin.m2m2.web.mvc.rest.v1.mapping;

import java.io.IOException;
import java.util.List;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.deser.std.StdDeserializer;
import com.serotonin.m2m2.module.ModelDefinition;
import com.serotonin.m2m2.module.ModuleRegistry;
import com.serotonin.m2m2.web.mvc.rest.v1.model.SuperclassModel;

/**
 * @author Terry Packer
 *
 */
public class SuperclassModelDeserializer extends StdDeserializer<SuperclassModel<?>>{

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	

	/**
	 * 
	 */
	protected SuperclassModelDeserializer() {
		super(SuperclassModel.class);
	}

	/* (non-Javadoc)
	 * @see com.fasterxml.jackson.databind.JsonDeserializer#deserialize(com.fasterxml.jackson.core.JsonParser, com.fasterxml.jackson.databind.DeserializationContext)
	 */
	@Override
	public SuperclassModel<?> deserialize(JsonParser jp,
			DeserializationContext ctxt) throws IOException,
			JsonProcessingException {
		ObjectMapper mapper = (ObjectMapper) jp.getCodec();  
		JsonNode tree = jp.readValueAsTree();
	    //ObjectNode root = (ObjectNode) mapper.readTree(jp);
	    ModelDefinition definition = findModelDefinition(tree.get("type").asText());
	    //TODO if model is NULL We need to let the USER know this!
	    return (SuperclassModel<?>) mapper.treeToValue(tree, definition.createModel().getClass());
	}

	/**
	 * @return
	 */
	public ModelDefinition findModelDefinition(String typeName) {
		List<ModelDefinition> definitions = ModuleRegistry.getDefinitions(ModelDefinition.class);
		for(ModelDefinition definition : definitions){
			if(definition.getModelTypeName().equalsIgnoreCase(typeName))
				return definition;
		}
		return null; //TODO Somehow notify Mango 
	}

}
