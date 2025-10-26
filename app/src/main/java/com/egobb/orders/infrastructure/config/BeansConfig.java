package com.egobb.orders.infrastructure.config;

import com.egobb.orders.domain.model.StateMachine;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BeansConfig {
	@Bean
	StateMachine stateMachine() {
		return new StateMachine();
	}
}
