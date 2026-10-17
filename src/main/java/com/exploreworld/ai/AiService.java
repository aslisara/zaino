package com.exploreworld.ai;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

@Service
public class AiService {

    private static final Logger log = LoggerFactory.getLogger(AiService.class);

    private static final String SYSTEM_PROMPT =
            "Sen deneyimli bir seyahat rehberisin. Türkçe, net ve kısa yanıt ver.";

    private final RestClient client;
    private final String apiKey;
    private final String model;
    private final int maxTokens;

    public AiService(@Value("${anthropic.api-key:}") String apiKey,
                     @Value("${anthropic.model}") String model,
                     @Value("${anthropic.max-tokens}") int maxTokens) {
        this.apiKey = apiKey;
        this.model = model;
        this.maxTokens = maxTokens;
        this.client = RestClient.builder().baseUrl("https://api.anthropic.com").build();
      
    }

    @SuppressWarnings("unchecked")
    public String ask(String prompt) {
        if (apiKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Yapay zekâ yapılandırılmamış");
        }

        Map<String, Object> body = Map.of(
                "model", model,
                "max_tokens", maxTokens,
                "system", SYSTEM_PROMPT,
                "messages", List.of(Map.of("role", "user", "content", prompt)));

        try {
            Map<String, Object> response = client.post()
                    .uri("/v1/messages")
                    .header("x-api-key", apiKey)
                    .header("anthropic-version", "2023-06-01")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(Map.class);

            List<Map<String, Object>> content = (List<Map<String, Object>>) response.get("content");
            return (String) content.get(0).get("text");
        } catch (RestClientException | NullPointerException e) {
            log.warn("Anthropic çağrısı başarısız: {}", e.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Yapay zekâ servisine ulaşılamadı");
        }
    }
}