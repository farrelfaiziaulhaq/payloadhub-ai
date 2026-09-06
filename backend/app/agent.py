"""LangChain agentic pipeline: LLM function-calling router + anti-hallucination guardrails.

The LLM acts purely as a *router/reasoner*: it reads the user context, decides
which deterministic tool(s) to call and with which arguments, then relays the
tool observations back to the user. It is explicitly forbidden from inventing
payload syntax, CVE identifiers, or tool results.
"""

from __future__ import annotations

from typing import Any, Dict, List

from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from .config import Settings, get_settings
from .tools import AGENT_TOOLS

SYSTEM_PROMPT = """\
You are a deterministic pentesting assistant for authorized security testing only.
Rules: never invent payloads, CVEs, or facts.
- Reverse shell -> call generate_reverse_shell_tool, echo its result verbatim.
- Nmap text -> call parse_nmap_cve_tool. If cves is empty, say no known CVE.
- JWT -> call jwt_analyzer_tool, report only what it returns.
If no tool fits or a tool errors, say so and ask for missing parameters.
Be extremely brief: give the payload/result, then at most one short line of
essential explanation. No steps, no tips, no formatting beyond a code block.
"""


def _build_chat_model(settings: Settings) -> ChatOpenAI:
    """Construct a deterministic (temperature=0) LLM for function calling."""
    kwargs: Dict[str, Any] = {
        "model": settings.llm_model,
        "api_key": settings.llm_api_key,
        "temperature": settings.llm_temperature,
        "max_tokens": settings.llm_max_tokens,
        "timeout": settings.request_timeout_seconds,
    }
    if settings.llm_base_url:
        kwargs["base_url"] = settings.llm_base_url
    return ChatOpenAI(**kwargs)


def build_agent_executor(settings: Settings) -> AgentExecutor:
    """Build the LangChain tool-calling agent executor."""
    llm = _build_chat_model(settings)

    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM_PROMPT),
            ("placeholder", "{chat_history}"),
            ("human", "{input}"),
            ("placeholder", "{agent_scratchpad}"),
        ]
    )

    agent = create_tool_calling_agent(llm, AGENT_TOOLS, prompt)

    return AgentExecutor(
        agent=agent,
        tools=AGENT_TOOLS,
        verbose=False,
        handle_parsing_errors=True,
        max_iterations=settings.agent_max_iterations,
        max_execution_time=settings.agent_timeout_seconds,
        return_intermediate_steps=True,
    )


def extract_tools_used(result: Dict[str, Any]) -> List[str]:
    """Return the ordered list of tool names the agent invoked."""
    tool_names: List[str] = []
    for step in result.get("intermediate_steps", []) or []:
        action = step[0] if isinstance(step, (tuple, list)) and step else None
        tool_name = getattr(action, "tool", None)
        if tool_name:
            tool_names.append(str(tool_name))
    return tool_names
