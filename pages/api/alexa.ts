import type { NextApiRequest, NextApiResponse } from 'next'

// Define a type for the Alexa request body for better type safety
interface AlexaRequestBody {
  version?: string
  session?: {
    new: boolean
    sessionId: string
    application: {
      applicationId: string
    }
    user: {
      userId: string
    }
  }
  context?: any // You can define this further if needed
  request?: {
    type: string
    requestId: string
    timestamp: string
    locale: string
    intent?: {
      name: string
      confirmationStatus?: string
      slots?: {
        [key: string]: {
          name: string
          value?: string
          confirmationStatus?: string
          source?: string
        }
      }
    }
    reason?: string // For SessionEndedRequest
  }
}

export default async function handler( // Made handler async for ntfy POST
  req: NextApiRequest,
  res: NextApiResponse
) {
  console.log('!!!!!!!!!!!!!! ALEXA HANDLER CALLED !!!!!!!!!!!!!!')
  console.log('Request Method:', req.method)
  console.log('Request Headers:', JSON.stringify(req.headers, null, 2))

  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST'])
    console.log(`Method ${req.method} Not Allowed`)
    return res.status(405).end(`Method ${req.method} Not Allowed`)
  }

  // Log the raw body if possible
  // Note: req.body is automatically parsed by Next.js for application/json
  if (req.body) {
    console.log('Request Body:', JSON.stringify(req.body, null, 2))
  } else {
    console.log('Request Body: undefined or not parsed')
    // If body is undefined, it's a problem, return an error response
    const errorResponse = {
      version: '1.0',
      response: {
        outputSpeech: {
          type: 'PlainText',
          text: 'Error: Request body is missing or not parsed.',
        },
        shouldEndSession: true,
      },
    }
    console.log('Sending Error Response due to missing body:', JSON.stringify(errorResponse, null, 2))
    res.setHeader('Content-Type', 'application/json')
    return res.status(400).json(errorResponse)
  }

  const alexaRequest = req.body as AlexaRequestBody

  let speechText = 'Sorry, I could not understand what you said.'
  let shouldEndSession = true // Default to true, can be overridden

  // Log the parsed Alexa request for debugging
  console.log('Parsed Alexa Request Body:', JSON.stringify(alexaRequest, null, 2))

  if (alexaRequest.request?.type === 'LaunchRequest') {
    speechText = 'Welcome to fu fu. What can I do for you?'
    shouldEndSession = false
  } else if (alexaRequest.request?.type === 'IntentRequest') {
    const intentName = alexaRequest.request.intent?.name
    if (intentName === 'CatchAllIntent' || intentName === 'AMAZON.FallbackIntent') {
      const phraseSlot = alexaRequest.request.intent?.slots?.phrase
      if (phraseSlot && phraseSlot.value) {
        speechText = `You said: ${phraseSlot.value}`
        console.log(`${intentName}: Detected phrase: "${phraseSlot.value}"`)

        // Post to ntfy
        try {
          console.log(`Attempting to POST to ntfy.henkin.world/foo with phrase: "${phraseSlot.value}"`)
          const ntfyResponse = await fetch('https://ntfy.henkin.world/foo', {
            method: 'POST',
            body: phraseSlot.value,
            headers: {
              'Content-Type': 'text/plain',
            },
          })
          if (ntfyResponse.ok) {
            console.log(`Successfully posted to ntfy.henkin.world/foo. Status: ${ntfyResponse.status}`)
          } else {
            console.error(`Failed to post to ntfy.henkin.world/foo. Status: ${ntfyResponse.status}, Body: ${await ntfyResponse.text()}`)
          }
        } catch (error) {
          console.error('Error posting to ntfy.henkin.world/foo:', error)
        }
      } else {
        if (intentName === 'AMAZON.FallbackIntent') {
          speechText = 'I think I heard you, but I am not sure what you meant. Can you try rephrasing?'
          console.log('AMAZON.FallbackIntent: No specific phrase captured in slots.')
        } else {
          speechText = 'I heard you, but I did not catch a specific phrase.'
          console.log('CatchAllIntent: No phrase value found in slots.')
        }
      }
    } else if (intentName === 'AMAZON.StopIntent' || intentName === 'AMAZON.CancelIntent') {
      speechText = 'Goodbye!'
      shouldEndSession = true
    } else if (intentName === 'AMAZON.HelpIntent') {
      speechText = 'You can say anything to me, and I will repeat it. For example, say "process my important message".'
      shouldEndSession = false
    } else {
      speechText = `I received an intent named ${intentName || 'UnknownIntent'}, but I don't know how to handle it yet.`
      console.log(`Unhandled IntentName: ${intentName}`)
    }
  } else if (alexaRequest.request?.type === 'SessionEndedRequest') {
    console.log(`Session ended because: ${alexaRequest.request.reason}`)
    return res.status(200).end() // No response body for SessionEndedRequest
  } else {
    speechText = 'I received an unknown request type.'
    console.log(`Unknown request type: ${alexaRequest.request?.type}`)
  }

  const alexaResponse = {
    version: '1.0',
    response: {
      outputSpeech: {
        type: 'PlainText',
        text: speechText,
      },
      shouldEndSession: shouldEndSession,
      // You can add card or reprompt here if needed
    },
    // sessionAttributes: { /* ... */ }
  }

  console.log('Sending Alexa Response:', JSON.stringify(alexaResponse, null, 2))
  res.setHeader('Content-Type', 'application/json')
  res.status(200).json(alexaResponse)
} 

