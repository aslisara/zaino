package com.exploreworld.ai;

import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final AiService aiService;
    private final AiUsageService usageService;

    public AiController(AiService aiService, AiUsageService usageService) {
        this.aiService = aiService;
        this.usageService = usageService;
    }

    @PostMapping
    public AiResponse ask(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody AiRequest request) {
        usageService.consume(Long.valueOf(jwt.getSubject()));
        return new AiResponse(aiService.ask(request.prompt()));
    }
}
